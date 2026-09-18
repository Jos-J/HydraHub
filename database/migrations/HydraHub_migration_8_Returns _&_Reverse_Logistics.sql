------------------------------------------------------------------------
-----------------------Migration 8 — Returns & Reverse Logistics
------------------------------------------------------------------------
------------------------------------------------------------------------
----------------trg_prevent_delivery_event_mutation trigger
------------------------------------------------------------------------
CREATE TRIGGER trg_prevent_delivery_event_mutation
BEFORE UPDATE OR DELETE
ON fulfillment.delivery_events
FOR EACH ROW
EXECUTE FUNCTION fulfillment.prevent_delivery_event_mutation();

-------------------------------------------------------------------------
--------------------fulfillment.prevent.delivery.event mutation function 
-------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.prevent_delivery_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    RAISE EXCEPTION
        'Delivery events are immutable and cannot be updated or deleted'
        USING ERRCODE = 'P0001';
END;
$function$;

---------------------------------------------------------------------------
-------------------fulfilment.transistion_package_delivery_status function
---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fulfillment.transition_package_delivery_status(
    p_package_id BIGINT,
    p_new_status_code VARCHAR(30),
    p_performed_by_user_id INTEGER DEFAULT NULL,
    p_reason TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS fulfillment.packages
LANGUAGE plpgsql
AS $function$
DECLARE
    v_package fulfillment.packages%ROWTYPE;
    v_updated_package fulfillment.packages%ROWTYPE;

    v_previous_status_code VARCHAR(30);
    v_event_at TIMESTAMP WITHOUT TIME ZONE;
BEGIN
    /*
     * Validate parameters.
     */
    IF p_package_id IS NULL THEN
        RAISE EXCEPTION
            'package_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_package_id <= 0 THEN
        RAISE EXCEPTION
            'package_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_new_status_code IS NULL
       OR btrim(p_new_status_code) = '' THEN
        RAISE EXCEPTION
            'new delivery status is required'
            USING ERRCODE = '22023';
    END IF;

    IF p_reason IS NOT NULL
       AND btrim(p_reason) = '' THEN
        RAISE EXCEPTION
            'reason cannot be blank when supplied'
            USING ERRCODE = '22023';
    END IF;

    IF p_metadata IS NOT NULL
       AND jsonb_typeof(p_metadata) <> 'object' THEN
        RAISE EXCEPTION
            'metadata must be a JSON object when supplied'
            USING ERRCODE = '22023';
    END IF;

    /*
     * Make sure the requested status exists.
     */
    IF NOT EXISTS (
        SELECT 1
        FROM fulfillment.delivery_statuses
        WHERE status_code = p_new_status_code
    ) THEN
        RAISE EXCEPTION
            'Delivery status % does not exist',
            p_new_status_code
            USING ERRCODE = '22023';
    END IF;

    /*
     * Lock the package.
     *
     * This serializes competing delivery transitions for the
     * same physical package.
     */
    SELECT *
    INTO v_package
    FROM fulfillment.packages
    WHERE package_id = p_package_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Package % does not exist',
            p_package_id
            USING ERRCODE = 'P0002';
    END IF;

    v_previous_status_code :=
        v_package.delivery_status_code;

    /*
     * Prevent no-op transitions.
     */
    IF v_previous_status_code = p_new_status_code THEN
        RAISE EXCEPTION
            'Package % is already in delivery status %',
            p_package_id,
            p_new_status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Validate the delivery state machine.
     */
    IF NOT (
        (
            v_previous_status_code = 'pending'
            AND p_new_status_code IN (
                'in_transit',
                'returned_to_sender'
            )
        )
        OR
        (
            v_previous_status_code = 'in_transit'
            AND p_new_status_code IN (
                'delivered',
                'delivery_failed',
                'lost',
                'returned_to_sender'
            )
        )
        OR
        (
            v_previous_status_code = 'delivery_failed'
            AND p_new_status_code IN (
                'in_transit',
                'returned_to_sender'
            )
        )
    ) THEN
        RAISE EXCEPTION
            'Invalid package delivery transition for package %: % -> %',
            p_package_id,
            v_previous_status_code,
            p_new_status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * If an internal user performed the transition,
     * they must belong to the package organization.
     */
    IF p_performed_by_user_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM public.organization_users ou
           WHERE ou.organization_id =
                 v_package.organization_id
             AND ou.user_id =
                 p_performed_by_user_id
             AND ou.is_active = TRUE
       ) THEN
        RAISE EXCEPTION
            'User % is not an active member of organization %',
            p_performed_by_user_id,
            v_package.organization_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Use one timestamp for both the package state change
     * and its immutable history event.
     */
    v_event_at := CURRENT_TIMESTAMP;

    /*
     * Update current package state.
     *
     * delivered_at is established only when the package reaches
     * delivered. Terminal states cannot transition afterward,
     * so this timestamp cannot later be rewritten normally.
     */
    UPDATE fulfillment.packages
    SET
        delivery_status_code = p_new_status_code,

        delivered_at =
            CASE
                WHEN p_new_status_code = 'delivered'
                    THEN v_event_at
                ELSE NULL
            END,

        updated_at = v_event_at
    WHERE package_id = v_package.package_id
    RETURNING *
    INTO v_updated_package;

    /*
     * Append immutable delivery history.
     */
    INSERT INTO fulfillment.delivery_events (
        organization_id,
        shipment_id,
        package_id,
        event_type,
        previous_status_code,
        new_status_code,
        reason,
        metadata,
        performed_by_user_id,
        event_at
    )
    VALUES (
        v_package.organization_id,
        v_package.shipment_id,
        v_package.package_id,
        'status_changed',
        v_previous_status_code,
        p_new_status_code,
        p_reason,
        COALESCE(p_metadata, '{}'::jsonb),
        p_performed_by_user_id,
        v_event_at
    );

    RETURN v_updated_package;
END;
$function$;


---------------------------------------------------------------------
--------------------fulfillment.delivery table
---------------------------------------------------------------------
CREATE TABLE fulfillment.delivery_events (
    delivery_event_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    shipment_id BIGINT NOT NULL,
    package_id BIGINT NOT NULL,

    event_type VARCHAR(50) NOT NULL,

    previous_status_code VARCHAR(30),
    new_status_code VARCHAR(30) NOT NULL,

    reason TEXT,
    metadata JSONB,

    performed_by_user_id INTEGER,

    event_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT delivery_events_org_event_unique
        UNIQUE (
            organization_id,
            delivery_event_id
        ),

    -- Package must belong to this organization and shipment.
    CONSTRAINT delivery_events_package_fk
        FOREIGN KEY (
            organization_id,
            package_id,
            shipment_id
        )
        REFERENCES fulfillment.packages (
            organization_id,
            package_id,
            shipment_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    -- Both previous and new states must be real delivery statuses.
    CONSTRAINT delivery_events_previous_status_fk
        FOREIGN KEY (previous_status_code)
        REFERENCES fulfillment.delivery_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT delivery_events_new_status_fk
        FOREIGN KEY (new_status_code)
        REFERENCES fulfillment.delivery_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT delivery_events_performed_by_user_fk
        FOREIGN KEY (performed_by_user_id)
        REFERENCES public.users (user_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT delivery_events_event_type_not_blank
        CHECK (BTRIM(event_type) <> ''),

    CONSTRAINT delivery_events_event_type_format
        CHECK (
            event_type = LOWER(event_type)
            AND event_type ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT delivery_events_reason_not_blank
        CHECK (
            reason IS NULL
            OR BTRIM(reason) <> ''
        ),

    CONSTRAINT delivery_events_metadata_object
        CHECK (
            metadata IS NULL
            OR jsonb_typeof(metadata) = 'object'
        )
);

------------------------------------------------------------------------
-----------------------fulfillment.package_contents table
------------------------------------------------------------------------

CREATE TABLE fulfillment.package_contents (
    package_content_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    package_id BIGINT NOT NULL,
    shipment_id BIGINT NOT NULL,
    shipment_item_id BIGINT NOT NULL,

    quantity INTEGER NOT NULL,

    metadata JSONB,

    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT package_contents_org_content_unique
        UNIQUE (
            organization_id,
            package_content_id
        ),

    -- A shipment item gets one content row per package.
    CONSTRAINT package_contents_package_shipment_item_unique
        UNIQUE (
            package_id,
            shipment_item_id
        ),

    -- Package must belong to this organization and shipment.
    CONSTRAINT package_contents_package_fk
        FOREIGN KEY (
            organization_id,
            package_id,
            shipment_id
        )
        REFERENCES fulfillment.packages (
            organization_id,
            package_id,
            shipment_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    -- Shipment item must belong to the SAME organization and shipment.
    CONSTRAINT package_contents_shipment_item_fk
        FOREIGN KEY (
            organization_id,
            shipment_item_id,
            shipment_id
        )
        REFERENCES fulfillment.shipment_items (
            organization_id,
            shipment_item_id,
            shipment_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT package_contents_quantity_positive
        CHECK (quantity > 0)
);


------------------------------------------------------------------------
-------------------fulfillment.packages table
-----------------------------------------------------------------------
CREATE TABLE fulfillment.packages (
    package_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    shipment_id BIGINT NOT NULL,
    fulfillment_order_id BIGINT NOT NULL,

    package_number VARCHAR(50) NOT NULL,

    status_code VARCHAR(30) NOT NULL DEFAULT 'open',
    delivery_status_code VARCHAR(30) NOT NULL DEFAULT 'pending',

    tracking_number VARCHAR(255),

    sealed_at TIMESTAMP WITHOUT TIME ZONE,
    shipped_at TIMESTAMP WITHOUT TIME ZONE,
    delivered_at TIMESTAMP WITHOUT TIME ZONE,

    metadata JSONB,

    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT packages_org_package_unique
        UNIQUE (
            organization_id,
            package_id
        ),

    CONSTRAINT packages_org_number_unique
        UNIQUE (
            organization_id,
            package_number
        ),

    CONSTRAINT packages_org_package_shipment_unique
        UNIQUE (
            organization_id,
            package_id,
            shipment_id
        ),

    CONSTRAINT packages_shipment_fk
        FOREIGN KEY (
            organization_id,
            shipment_id,
            fulfillment_order_id
        )
        REFERENCES fulfillment.shipments (
            organization_id,
            shipment_id,
            fulfillment_order_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT packages_status_fk
        FOREIGN KEY (status_code)
        REFERENCES fulfillment.package_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT packages_delivery_status_fk
        FOREIGN KEY (delivery_status_code)
        REFERENCES fulfillment.delivery_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT packages_number_not_blank
        CHECK (BTRIM(package_number) <> ''),

    CONSTRAINT packages_tracking_number_not_blank
        CHECK (
            tracking_number IS NULL
            OR BTRIM(tracking_number) <> ''
        ),

    CONSTRAINT packages_delivered_timestamp_consistency
        CHECK (
            (
                delivery_status_code = 'delivered'
                AND delivered_at IS NOT NULL
            )
            OR
            (
                delivery_status_code <> 'delivered'
                AND delivered_at IS NULL
            )
        )
);

------------------------------------------------------------------------
----------------------- fulfillment.shipment_items table
-----------------------------------------------------------------------
CREATE TABLE fulfillment.shipment_items (
    shipment_item_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    shipment_id BIGINT NOT NULL,
    fulfillment_order_id BIGINT NOT NULL,
    fulfillment_order_item_id BIGINT NOT NULL,

    quantity INTEGER NOT NULL,

    metadata JSONB,

    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Allows child tables such as package contents to reference
    -- an organization-scoped shipment item later.
    CONSTRAINT shipment_items_org_item_unique
        UNIQUE (
            organization_id,
            shipment_item_id
        ),

    -- Don't allow the same fulfillment item to appear twice
    -- inside the same shipment.
    CONSTRAINT shipment_items_shipment_fulfillment_item_unique
        UNIQUE (
            shipment_id,
            fulfillment_order_item_id
        ),

    -- Shipment must belong to this organization AND
    -- this fulfillment order.
    CONSTRAINT shipment_items_shipment_fk
        FOREIGN KEY (
            organization_id,
            shipment_id,
            fulfillment_order_id
        )
        REFERENCES fulfillment.shipments (
            organization_id,
            shipment_id,
            fulfillment_order_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    -- Fulfillment item must actually belong to the
    -- stated fulfillment order.
    CONSTRAINT shipment_items_fulfillment_item_fk
        FOREIGN KEY (
            fulfillment_order_id,
            fulfillment_order_item_id
        )
        REFERENCES fulfillment.fulfillment_order_items (
            fulfillment_order_id,
            fulfillment_order_item_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT shipment_items_quantity_positive
        CHECK (quantity > 0)
);

------------------------------------------------------------------------
-----------------------------fulfillment.shipments table
------------------------------------------------------------------------

CREATE TABLE fulfillment.shipments (
    shipment_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    fulfillment_order_id BIGINT NOT NULL,

    shipment_number VARCHAR(50) NOT NULL,

    status_code VARCHAR(30) NOT NULL DEFAULT 'pending',

    carrier_code VARCHAR(50),
    service_level VARCHAR(100),

    shipped_at TIMESTAMP WITHOUT TIME ZONE,

    metadata JSONB,

    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT shipments_org_shipment_unique
        UNIQUE (organization_id, shipment_id),

    CONSTRAINT shipments_org_number_unique
        UNIQUE (organization_id, shipment_number),

    CONSTRAINT shipments_fulfillment_order_fk
        FOREIGN KEY (
            organization_id,
            fulfillment_order_id
        )
        REFERENCES fulfillment.fulfillment_orders (
            organization_id,
            fulfillment_order_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT shipments_status_code_fk
        FOREIGN KEY (status_code)
        REFERENCES fulfillment.shipment_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT shipments_number_not_blank
        CHECK (BTRIM(shipment_number) <> ''),

    CONSTRAINT shipments_carrier_code_not_blank
        CHECK (
            carrier_code IS NULL
            OR BTRIM(carrier_code) <> ''
        ),

    CONSTRAINT shipments_service_level_not_blank
        CHECK (
            service_level IS NULL
            OR BTRIM(service_level) <> ''
        ),

    CONSTRAINT shipments_shipped_not_before_created
        CHECK (
            shipped_at IS NULL
            OR shipped_at >= created_at
        ),

    CONSTRAINT shipments_status_timestamp_consistency
        CHECK (
            (
                status_code = 'shipped'
                AND shipped_at IS NOT NULL
            )
            OR
            (
                status_code <> 'shipped'
                AND shipped_at IS NULL
            )
        )
);


------------------------------------------------------------------------
-------------------------delivery_statuses table
----------------------------------------------------------------------
CREATE TABLE fulfillment.delivery_statuses (
    status_code VARCHAR(30) PRIMARY KEY,
    display_name VARCHAR(50) NOT NULL,
    description TEXT,
    is_terminal BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order SMALLINT NOT NULL,

    CONSTRAINT delivery_statuses_status_code_format
        CHECK (
            status_code = LOWER(status_code)
            AND status_code ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT delivery_statuses_display_name_not_blank
        CHECK (BTRIM(display_name) <> ''),

    CONSTRAINT delivery_statuses_sort_order_positive
        CHECK (sort_order > 0),

    CONSTRAINT delivery_statuses_sort_order_unique
        UNIQUE (sort_order)
);


------------------------------------------------------------------------
----------------- trigger trg_validate_return_item_quantity
------------------------------------------------------------------------
CREATE TRIGGER trg_validate_return_item_quantity
BEFORE INSERT OR UPDATE OF
    quantity_requested,
    sales_order_item_id,
    sales_order_id,
    organization_id
ON returns.return_items
FOR EACH ROW
EXECUTE FUNCTION returns.validate_return_item_quantity();
------------------------------------------------------------------------
----------------- function returns.validate_return_item_quantity
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION returns.validate_return_item_quantity()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_fulfilled_quantity INTEGER;
    v_reserved_quantity  INTEGER;
BEGIN
    -- Lock the original sales-order item so concurrent return requests
    -- cannot both reserve the same remaining quantity.
    SELECT soi.fulfilled_quantity
    INTO v_fulfilled_quantity
    FROM public.sales_order_items soi
    WHERE soi.sales_order_item_id = NEW.sales_order_item_id
      AND soi.sales_order_id = NEW.sales_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Sales order item % was not found for sales order %',
            NEW.sales_order_item_id,
            NEW.sales_order_id;
    END IF;

    SELECT COALESCE(SUM(ri.quantity_requested), 0)
    INTO v_reserved_quantity
    FROM returns.return_items ri
    JOIN returns.returns r
      ON r.return_id = ri.return_id
     AND r.organization_id = ri.organization_id
    JOIN returns.return_statuses rs
      ON rs.return_status_id = r.return_status_id
    WHERE ri.organization_id = NEW.organization_id
      AND ri.sales_order_item_id = NEW.sales_order_item_id
      AND rs.status_code NOT IN ('rejected', 'cancelled')
      AND (
            TG_OP = 'INSERT'
            OR ri.return_item_id <> NEW.return_item_id
          );

    IF v_reserved_quantity + NEW.quantity_requested > v_fulfilled_quantity THEN
        RAISE EXCEPTION
            'Return quantity exceeds fulfilled quantity. Fulfilled: %, already reserved: %, requested: %, remaining: %',
            v_fulfilled_quantity,
            v_reserved_quantity,
            NEW.quantity_requested,
            v_fulfilled_quantity - v_reserved_quantity;
    END IF;

    RETURN NEW;
END;
$$;

------------------------------------------------------------------------
-----------------table returns.return_items
------------------------------------------------------------------------
CREATE TABLE returns.return_items (
    return_item_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    return_id BIGINT NOT NULL,

    sales_order_id INTEGER NOT NULL,
    sales_order_item_id INTEGER NOT NULL,

    variant_id INTEGER NOT NULL,
    return_reason_id INTEGER NOT NULL,

    quantity_requested INTEGER NOT NULL,
    quantity_approved INTEGER,
    quantity_received INTEGER NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_return_items_org_return_item
        UNIQUE (organization_id, return_item_id),

    CONSTRAINT uq_return_items_return_sales_item
        UNIQUE (
            organization_id,
            return_id,
            sales_order_item_id
        ),

    CONSTRAINT fk_return_items_return
        FOREIGN KEY (
            organization_id,
            return_id
        )
        REFERENCES returns.returns (
            organization_id,
            return_id
        ),

    CONSTRAINT fk_return_items_sales_order_item
        FOREIGN KEY (
            sales_order_id,
            sales_order_item_id
        )
        REFERENCES public.sales_order_items (
            sales_order_id,
            sales_order_item_id
        ),

    CONSTRAINT fk_return_items_variant
        FOREIGN KEY (variant_id)
        REFERENCES public.product_variants (variant_id),

    CONSTRAINT fk_return_items_reason
        FOREIGN KEY (
            organization_id,
            return_reason_id
        )
        REFERENCES returns.return_reasons (
            organization_id,
            return_reason_id
        ),

    CONSTRAINT chk_return_items_quantity_requested
        CHECK (quantity_requested > 0),

    CONSTRAINT chk_return_items_quantity_approved
        CHECK (
            quantity_approved IS NULL
            OR (
                quantity_approved > 0
                AND quantity_approved <= quantity_requested
            )
        ),

    CONSTRAINT chk_return_items_quantity_received
        CHECK (
            quantity_received >= 0
        ),

    CONSTRAINT chk_return_items_received_not_above_approved
        CHECK (
            quantity_approved IS NULL
            OR quantity_received <= quantity_approved
        )
);

------------------------------------------------------------------------
----------------table returns.returns_reasons
------------------------------------------------------------------------
CREATE TABLE returns.return_reasons (
    return_reason_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,

    reason_code VARCHAR(50) NOT NULL,
    reason_name VARCHAR(100) NOT NULL,
    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_return_reasons_organization
        FOREIGN KEY (organization_id)
        REFERENCES public.organizations (organization_id),

    CONSTRAINT uq_return_reasons_org_code
        UNIQUE (organization_id, reason_code),

    CONSTRAINT uq_return_reasons_org_reason_id
        UNIQUE (organization_id, return_reason_id),

    CONSTRAINT chk_return_reasons_code_not_blank
        CHECK (btrim(reason_code) <> ''),

    CONSTRAINT chk_return_reasons_name_not_blank
        CHECK (btrim(reason_name) <> '')
);


------------------------------------------------------------------------
---------------table returns.returns
------------------------------------------------------------------------

CREATE TABLE returns.returns (
    return_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    return_number VARCHAR(50) NOT NULL,

    sales_order_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,

    return_status_id INTEGER NOT NULL,

    initiated_by VARCHAR(20) NOT NULL,
    initiated_by_user_id INTEGER,

    requested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    approved_at TIMESTAMPTZ,
    approved_by_user_id INTEGER,

    rejected_at TIMESTAMPTZ,
    rejected_by_user_id INTEGER,
    rejection_reason TEXT,

    cancelled_at TIMESTAMPTZ,
    cancelled_by_user_id INTEGER,
    cancellation_reason TEXT,

    received_at TIMESTAMPTZ,
    inspection_started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    customer_notes TEXT,
    internal_notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_returns_org_return_number
        UNIQUE (organization_id, return_number),

    CONSTRAINT uq_returns_org_return_id
        UNIQUE (organization_id, return_id),

    CONSTRAINT fk_returns_organization
        FOREIGN KEY (organization_id)
        REFERENCES public.organizations (organization_id),

    CONSTRAINT fk_returns_sales_order
        FOREIGN KEY (organization_id, sales_order_id)
        REFERENCES public.sales_orders (organization_id, sales_order_id),

    CONSTRAINT fk_returns_customer
        FOREIGN KEY (organization_id, customer_id)
        REFERENCES public.customers (organization_id, customer_id),

    CONSTRAINT fk_returns_status
        FOREIGN KEY (return_status_id)
        REFERENCES returns.return_statuses (return_status_id),

    CONSTRAINT fk_returns_initiated_by_user
        FOREIGN KEY (organization_id, initiated_by_user_id)
        REFERENCES public.organization_users (organization_id, user_id),

    CONSTRAINT fk_returns_approved_by_user
        FOREIGN KEY (organization_id, approved_by_user_id)
        REFERENCES public.organization_users (organization_id, user_id),

    CONSTRAINT fk_returns_rejected_by_user
        FOREIGN KEY (organization_id, rejected_by_user_id)
        REFERENCES public.organization_users (organization_id, user_id),

    CONSTRAINT fk_returns_cancelled_by_user
        FOREIGN KEY (organization_id, cancelled_by_user_id)
        REFERENCES public.organization_users (organization_id, user_id),

    CONSTRAINT chk_returns_return_number_not_blank
        CHECK (btrim(return_number) <> ''),

    CONSTRAINT chk_returns_initiated_by
        CHECK (
            initiated_by IN (
                'customer',
                'employee',
                'manager',
                'system'
            )
        ),

    CONSTRAINT chk_returns_initiator_user
        CHECK (
            (initiated_by IN ('employee', 'manager')
                AND initiated_by_user_id IS NOT NULL)
            OR
            (initiated_by IN ('customer', 'system')
                AND initiated_by_user_id IS NULL)
        )
);


------------------------------------------------------------------------
--------------------table returns.return_statuses
------------------------------------------------------------------------
CREATE TABLE returns.return_statuses (
    return_status_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    status_code VARCHAR(30) NOT NULL,
    status_name VARCHAR(50) NOT NULL,

    is_terminal BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_return_statuses_code
        UNIQUE (status_code),

    CONSTRAINT chk_return_statuses_code_not_blank
        CHECK (btrim(status_code) <> ''),

    CONSTRAINT chk_return_statuses_name_not_blank
        CHECK (btrim(status_name) <> ''),

    CONSTRAINT chk_return_statuses_sort_order
        CHECK (sort_order > 0)
);