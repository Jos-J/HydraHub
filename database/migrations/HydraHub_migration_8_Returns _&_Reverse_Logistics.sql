--------------------------------------------------------------------------------
-----------------------Migration 8 — Returns & Reverse Logistics
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-------------------------fulfillment.validate_package_content_quantity function
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fulfillment.validate_package_content_quantity()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_shipment_item_quantity INTEGER;
    v_packaged_quantity BIGINT;
    v_remaining_quantity BIGINT;
BEGIN
    /*
     * Lock the shipment item.
     *
     * This serializes competing package allocations against
     * the same shipment item.
     */
    SELECT si.quantity
    INTO v_shipment_item_quantity
    FROM fulfillment.shipment_items si
    WHERE si.organization_id = NEW.organization_id
      AND si.shipment_id = NEW.shipment_id
      AND si.shipment_item_id = NEW.shipment_item_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Shipment item % does not exist for shipment % in organization %',
            NEW.shipment_item_id,
            NEW.shipment_id,
            NEW.organization_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Calculate quantity already allocated to packages.
     *
     * During UPDATE, exclude the existing package-content
     * row so its old quantity is not counted against its
     * replacement quantity.
     */
    SELECT COALESCE(SUM(pc.quantity), 0)
    INTO v_packaged_quantity
    FROM fulfillment.package_contents pc
    WHERE pc.organization_id = NEW.organization_id
      AND pc.shipment_id = NEW.shipment_id
      AND pc.shipment_item_id = NEW.shipment_item_id
      AND (
          TG_OP <> 'UPDATE'
          OR pc.package_content_id <> OLD.package_content_id
      );

    v_remaining_quantity :=
        v_shipment_item_quantity - v_packaged_quantity;

    /*
     * Package contents cannot represent more units than
     * exist on the shipment item.
     */
    IF NEW.quantity > v_remaining_quantity THEN
        RAISE EXCEPTION
            'Package content quantity exceeds shipment item quantity. Shipment item quantity: %, already packaged: %, requested: %, remaining: %',
            v_shipment_item_quantity,
            v_packaged_quantity,
            NEW.quantity,
            v_remaining_quantity
            USING ERRCODE = 'P0001';
    END IF;

    RETURN NEW;
END;
$function$;

--------------------------------------------------------------------------
---------------------fulfillment.validate_shipment_item_quantity function
--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fulfillment.validate_shipment_item_quantity()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_shipped_quantity   integer;
    v_allocated_quantity integer;
    v_packaged_quantity  integer;
    v_remaining_quantity integer;
BEGIN
    /*
     * Lock the fulfillment-order item whose shipped quantity
     * is the upper limit for shipment-item allocation.
     */
    SELECT foi.shipped_quantity
    INTO v_shipped_quantity
    FROM fulfillment.fulfillment_order_items foi
    WHERE foi.fulfillment_order_id = NEW.fulfillment_order_id
      AND foi.fulfillment_order_item_id = NEW.fulfillment_order_item_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment order item % does not exist for fulfillment order %',
            NEW.fulfillment_order_item_id,
            NEW.fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Determine how much of the fulfillment-order item has
     * already been allocated to other shipment items.
     *
     * On UPDATE, exclude the row being replaced.
     */
    SELECT COALESCE(SUM(si.quantity), 0)
    INTO v_allocated_quantity
    FROM fulfillment.shipment_items si
    WHERE si.fulfillment_order_id = NEW.fulfillment_order_id
      AND si.fulfillment_order_item_id = NEW.fulfillment_order_item_id
      AND (
            TG_OP <> 'UPDATE'
            OR si.shipment_item_id <> OLD.shipment_item_id
          );

    v_remaining_quantity :=
        v_shipped_quantity - v_allocated_quantity;

    IF NEW.quantity > v_remaining_quantity THEN
        RAISE EXCEPTION
            'Shipment item quantity exceeds shipped quantity. Shipped: %, already allocated: %, requested: %, remaining: %',
            v_shipped_quantity,
            v_allocated_quantity,
            NEW.quantity,
            v_remaining_quantity
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * On UPDATE, protect quantities already assigned to packages.
     *
     * A shipment item cannot be reduced below the amount that
     * package_contents already references.
     */
    IF TG_OP = 'UPDATE' THEN
        SELECT COALESCE(SUM(pc.quantity), 0)
        INTO v_packaged_quantity
        FROM fulfillment.package_contents pc
        WHERE pc.organization_id = OLD.organization_id
          AND pc.shipment_id = OLD.shipment_id
          AND pc.shipment_item_id = OLD.shipment_item_id;

        IF NEW.quantity < v_packaged_quantity THEN
            RAISE EXCEPTION
                'Shipment item quantity cannot be less than packaged quantity. Packaged: %, requested: %',
                v_packaged_quantity,
                NEW.quantity
                USING ERRCODE = 'P0001';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;
------------------------------------------------------------------------
-----------------------------fulfillment.shipment_events table
------------------------------------------------------------------------
CREATE TABLE fulfillment.shipment_events (
    shipment_event_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    shipment_id BIGINT NOT NULL,

    event_type VARCHAR(50) NOT NULL,

    previous_status_code VARCHAR(30),
    new_status_code VARCHAR(30) NOT NULL,

    reason TEXT,
    metadata JSONB,

    performed_by_user_id INTEGER,

    event_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT shipment_events_org_event_unique
        UNIQUE (organization_id, shipment_event_id),

    CONSTRAINT shipment_events_shipment_fk
        FOREIGN KEY (organization_id, shipment_id)
        REFERENCES fulfillment.shipments (
            organization_id,
            shipment_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT shipment_events_previous_status_fk
        FOREIGN KEY (previous_status_code)
        REFERENCES fulfillment.shipment_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT shipment_events_new_status_fk
        FOREIGN KEY (new_status_code)
        REFERENCES fulfillment.shipment_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT shipment_events_org_performed_by_user_fk
        FOREIGN KEY (
            organization_id,
            performed_by_user_id
        )
        REFERENCES public.organization_users (
            organization_id,
            user_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT shipment_events_event_type_not_blank
        CHECK (btrim(event_type) <> ''),

    CONSTRAINT shipment_events_event_type_format
        CHECK (
            event_type = lower(event_type)
            AND event_type ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT shipment_events_reason_not_blank
        CHECK (
            reason IS NULL
            OR btrim(reason) <> ''
        ),

    CONSTRAINT shipment_events_metadata_object
        CHECK (
            metadata IS NULL
            OR jsonb_typeof(metadata) = 'object'
        )
);
----------------------------------------------------------------------
----------------------------triggers---------------------------------
-----------------------------------------------------------------------
-------------------------validate package content quantity trigger
----------------------------------------------------------------------
CREATE TRIGGER trg_validate_package_content_quantity
BEFORE INSERT OR UPDATE OF
    quantity,
    organization_id,
    shipment_id,
    shipment_item_id
ON fulfillment.package_contents
FOR EACH ROW
EXECUTE FUNCTION fulfillment.validate_package_content_quantity();

-----------------------------------------------------------------------
--------------------- validate_shipment_item_quantity trigger
-----------------------------------------------------------------------

CREATE TRIGGER trg_validate_shipment_item_quantity
BEFORE INSERT OR UPDATE OF
    quantity,
    fulfillment_order_id,
    fulfillment_order_item_id
ON fulfillment.shipment_items
FOR EACH ROW
EXECUTE FUNCTION fulfillment.validate_shipment_item_quantity();

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

------------------------------------------------------------------
-------------fulfillment prevent shipment event mutation function
------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.prevent_shipment_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    RAISE EXCEPTION
        'Shipment events are immutable and cannot be updated or deleted'
        USING ERRCODE = 'P0001';
END;
$function$;

------------------------------------------------------------------------
-------------------trg_prevent shipment event mutation trigger
------------------------------------------------------------------------
---------------------------------------------------------------------
--------------------table fulfullment.packages alter
--------------------------------------------------------------------
ALTER TABLE fulfillment.packages
ADD CONSTRAINT packages_status_timestamp_consistency
CHECK (
       (
           status_code = 'open'
           AND sealed_at IS NULL
           AND shipped_at IS NULL
       )
    OR (
           status_code = 'sealed'
           AND sealed_at IS NOT NULL
           AND shipped_at IS NULL
       )
    OR (
           status_code = 'shipped'
           AND shipped_at IS NOT NULL
       )
    OR (
           status_code = 'voided'
           AND shipped_at IS NULL
       )
);
-------------------------------------------------------------
-----------------------fulfillment.packages_events table
-------------------------------------------------------------
CREATE TABLE fulfillment.package_events (
    package_event_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    shipment_id BIGINT NOT NULL,
    package_id BIGINT NOT NULL,

    event_type VARCHAR(50) NOT NULL,

    previous_status_code VARCHAR(30),
    new_status_code VARCHAR(30) NOT NULL,

    reason TEXT,
    metadata JSONB,

    performed_by_user_id INTEGER,

    event_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT package_events_org_event_unique
        UNIQUE (organization_id, package_event_id),

    CONSTRAINT package_events_package_fk
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

    CONSTRAINT package_events_previous_status_fk
        FOREIGN KEY (previous_status_code)
        REFERENCES fulfillment.package_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT package_events_new_status_fk
        FOREIGN KEY (new_status_code)
        REFERENCES fulfillment.package_statuses (status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT package_events_org_performed_by_user_fk
        FOREIGN KEY (
            organization_id,
            performed_by_user_id
        )
        REFERENCES public.organization_users (
            organization_id,
            user_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT package_events_event_type_not_blank
        CHECK (btrim(event_type) <> ''),

    CONSTRAINT package_events_event_type_format
        CHECK (
            event_type = lower(event_type)
            AND event_type ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT package_events_reason_not_blank
        CHECK (
            reason IS NULL
            OR btrim(reason) <> ''
        ),

    CONSTRAINT package_events_metadata_object
        CHECK (
            metadata IS NULL
            OR jsonb_typeof(metadata) = 'object'
        )
);
----------------------------------------------------------------------
-------------function fulfillment. prevent package event mutation 
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.prevent_package_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    RAISE EXCEPTION
        'Package events are immutable and cannot be updated or deleted'
        USING ERRCODE = 'P0001';
END;
$function$;
--------------------------------------------------------------------
--------------------------Trigger trg prevent package event mutation
-------------------------------------------------------------------

CREATE TRIGGER trg_prevent_package_event_mutation
BEFORE UPDATE OR DELETE
ON fulfillment.package_events
FOR EACH ROW
EXECUTE FUNCTION fulfillment.prevent_package_event_mutation();
---------------------------------------------------------------------
------------function fulfillment.transition_package_status
---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fulfillment.transition_package_status(
    p_package_id bigint,
    p_new_status_code character varying,
    p_performed_by_user_id integer DEFAULT NULL::integer,
    p_reason text DEFAULT NULL::text,
    p_metadata jsonb DEFAULT NULL::jsonb
)
RETURNS fulfillment.packages
LANGUAGE plpgsql
AS $function$
DECLARE
    v_package fulfillment.packages%ROWTYPE;
    v_updated_package fulfillment.packages%ROWTYPE;

    v_previous_status_code VARCHAR(30);
    v_event_at TIMESTAMP WITHOUT TIME ZONE;
    v_package_content_count BIGINT;
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
            'new package status is required'
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
     * Validate requested package status.
     */
    IF NOT EXISTS (
        SELECT 1
        FROM fulfillment.package_statuses
        WHERE status_code = p_new_status_code
    ) THEN
        RAISE EXCEPTION
            'Package status % does not exist',
            p_new_status_code
            USING ERRCODE = '22023';
    END IF;

    /*
     * Lock package so competing transitions for the same
     * physical package are serialized.
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

    v_previous_status_code := v_package.status_code;

    /*
     * Reject no-op transitions.
     */
    IF v_previous_status_code = p_new_status_code THEN
        RAISE EXCEPTION
            'Package % is already in status %',
            p_package_id,
            p_new_status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Physical package state machine.
     *
     * open   -> sealed / voided
     * sealed -> shipped
     *
     * Only an open package may be voided.
     *
     * shipped and voided are terminal.
     */
    IF NOT (
        (
            v_previous_status_code = 'open'
            AND p_new_status_code IN (
                'sealed',
                'voided'
            )
        )
        OR
        (
            v_previous_status_code = 'sealed'
            AND p_new_status_code = 'shipped'
        )
    ) THEN
        RAISE EXCEPTION
            'Invalid package transition for package %: % -> %',
            p_package_id,
            v_previous_status_code,
            p_new_status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * SEAL VALIDATION
     *
     * A physical package cannot become sealed unless it
     * contains at least one package-content row.
     *
     * An empty open package may still transition to voided.
     */
    IF p_new_status_code = 'sealed' THEN

        SELECT COUNT(*)
        INTO v_package_content_count
        FROM fulfillment.package_contents pc
        WHERE pc.organization_id = v_package.organization_id
          AND pc.shipment_id = v_package.shipment_id
          AND pc.package_id = v_package.package_id;

        IF v_package_content_count = 0 THEN
            RAISE EXCEPTION
                'Package % cannot become sealed without package contents',
                p_package_id
                USING ERRCODE = 'P0001';
        END IF;

    END IF;

    /*
     * Internal actors must have an active membership
     * in the package organization.
     */
    IF p_performed_by_user_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM public.organization_users ou
           WHERE ou.organization_id = v_package.organization_id
             AND ou.user_id = p_performed_by_user_id
             AND ou.is_active = TRUE
       ) THEN
        RAISE EXCEPTION
            'User % is not an active member of organization %',
            p_performed_by_user_id,
            v_package.organization_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * One timestamp for state mutation and immutable history.
     */
    v_event_at := CURRENT_TIMESTAMP;

    /*
     * Update physical package state.
     *
     * open -> sealed:
     *     establish sealed_at.
     *
     * sealed -> shipped:
     *     preserve sealed_at and establish shipped_at.
     *
     * open -> voided:
     *     sealed_at and shipped_at remain NULL.
     */
    UPDATE fulfillment.packages
    SET
        status_code = p_new_status_code,

        sealed_at =
            CASE
                WHEN p_new_status_code = 'sealed'
                    THEN v_event_at
                ELSE sealed_at
            END,

        shipped_at =
            CASE
                WHEN p_new_status_code = 'shipped'
                    THEN v_event_at
                ELSE NULL
            END,

        updated_at = v_event_at

    WHERE package_id = v_package.package_id
    RETURNING *
    INTO v_updated_package;

    /*
     * Append immutable physical package history.
     */
    INSERT INTO fulfillment.package_events (
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
------------------------------------------------------------
--------function fulfillment transition shipment status
------------------------------------------------------------

CREATE OR REPLACE FUNCTION fulfillment.transition_shipment_status(
    p_shipment_id bigint,
    p_new_status_code character varying,
    p_performed_by_user_id integer DEFAULT NULL,
    p_reason text DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS fulfillment.shipments
LANGUAGE plpgsql
AS $function$
DECLARE
    v_shipment fulfillment.shipments%ROWTYPE;
    v_updated_shipment fulfillment.shipments%ROWTYPE;

    v_previous_status_code VARCHAR(30);
    v_event_at TIMESTAMP WITHOUT TIME ZONE;

    v_shipment_item_count BIGINT;
    v_package_count BIGINT;
    v_unready_package_count BIGINT;
    v_unreconciled_item_count BIGINT;
BEGIN
    /*
     * Validate parameters.
     */
    IF p_shipment_id IS NULL THEN
        RAISE EXCEPTION
            'shipment_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_shipment_id <= 0 THEN
        RAISE EXCEPTION
            'shipment_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_new_status_code IS NULL
       OR btrim(p_new_status_code) = '' THEN
        RAISE EXCEPTION
            'new shipment status is required'
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
     * Validate requested shipment status.
     */
    IF NOT EXISTS (
        SELECT 1
        FROM fulfillment.shipment_statuses
        WHERE status_code = p_new_status_code
    ) THEN
        RAISE EXCEPTION
            'Shipment status % does not exist',
            p_new_status_code
            USING ERRCODE = '22023';
    END IF;

    /*
     * Lock shipment so competing transitions for the same
     * shipment are serialized.
     */
    SELECT *
    INTO v_shipment
    FROM fulfillment.shipments
    WHERE shipment_id = p_shipment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Shipment % does not exist',
            p_shipment_id
            USING ERRCODE = 'P0002';
    END IF;

    v_previous_status_code := v_shipment.status_code;

    /*
     * Reject no-op transitions.
     */
    IF v_previous_status_code = p_new_status_code THEN
        RAISE EXCEPTION
            'Shipment % is already in status %',
            p_shipment_id,
            p_new_status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Shipment state machine.
     *
     * pending -> ready / cancelled
     * ready   -> shipped / cancelled
     *
     * shipped and cancelled are terminal.
     */
    IF NOT (
        (
            v_previous_status_code = 'pending'
            AND p_new_status_code IN (
                'ready',
                'cancelled'
            )
        )
        OR
        (
            v_previous_status_code = 'ready'
            AND p_new_status_code IN (
                'shipped',
                'cancelled'
            )
        )
    ) THEN
        RAISE EXCEPTION
            'Invalid shipment transition for shipment %: % -> %',
            p_shipment_id,
            v_previous_status_code,
            p_new_status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * READY VALIDATION
     *
     * A shipment can become ready only when:
     *
     * 1. It contains at least one shipment item.
     * 2. It contains at least one active package.
     * 3. Every active package is sealed.
     * 4. Every shipment item is fully accounted for
     *    by package contents.
     */
    IF p_new_status_code = 'ready' THEN

        SELECT COUNT(*)
        INTO v_shipment_item_count
        FROM fulfillment.shipment_items
        WHERE organization_id = v_shipment.organization_id
          AND shipment_id = v_shipment.shipment_id;

        IF v_shipment_item_count = 0 THEN
            RAISE EXCEPTION
                'Shipment % cannot become ready without shipment items',
                p_shipment_id
                USING ERRCODE = 'P0001';
        END IF;

        SELECT COUNT(*)
        INTO v_package_count
        FROM fulfillment.packages
        WHERE organization_id = v_shipment.organization_id
          AND shipment_id = v_shipment.shipment_id
          AND status_code <> 'voided';

        IF v_package_count = 0 THEN
            RAISE EXCEPTION
                'Shipment % cannot become ready without an active package',
                p_shipment_id
                USING ERRCODE = 'P0001';
        END IF;

        SELECT COUNT(*)
        INTO v_unready_package_count
        FROM fulfillment.packages
        WHERE organization_id = v_shipment.organization_id
          AND shipment_id = v_shipment.shipment_id
          AND status_code <> 'voided'
          AND status_code <> 'sealed';

        IF v_unready_package_count > 0 THEN
            RAISE EXCEPTION
                'Shipment % cannot become ready because % active package(s) are not sealed',
                p_shipment_id,
                v_unready_package_count
                USING ERRCODE = 'P0001';
        END IF;

        /*
         * Every shipment-item quantity must exactly equal the
         * quantity assigned to active packages.
         *
         * Contents belonging to voided packages do not count.
         */
        SELECT COUNT(*)
        INTO v_unreconciled_item_count
        FROM fulfillment.shipment_items si
        WHERE si.organization_id = v_shipment.organization_id
          AND si.shipment_id = v_shipment.shipment_id
          AND si.quantity <> (
              SELECT COALESCE(SUM(pc.quantity), 0)
              FROM fulfillment.package_contents pc
              JOIN fulfillment.packages p
                ON p.organization_id = pc.organization_id
               AND p.package_id = pc.package_id
               AND p.shipment_id = pc.shipment_id
              WHERE pc.organization_id = si.organization_id
                AND pc.shipment_id = si.shipment_id
                AND pc.shipment_item_id = si.shipment_item_id
                AND p.status_code <> 'voided'
          );

        IF v_unreconciled_item_count > 0 THEN
            RAISE EXCEPTION
                'Shipment % cannot become ready because % shipment item(s) are not fully packaged',
                p_shipment_id,
                v_unreconciled_item_count
                USING ERRCODE = 'P0001';
        END IF;

    END IF;

    /*
     * SHIPPED VALIDATION
     */
    IF p_new_status_code = 'shipped' THEN

        SELECT COUNT(*)
        INTO v_package_count
        FROM fulfillment.packages
        WHERE organization_id = v_shipment.organization_id
          AND shipment_id = v_shipment.shipment_id
          AND status_code <> 'voided';

        IF v_package_count = 0 THEN
            RAISE EXCEPTION
                'Shipment % cannot become shipped without an active package',
                p_shipment_id
                USING ERRCODE = 'P0001';
        END IF;

        SELECT COUNT(*)
        INTO v_unready_package_count
        FROM fulfillment.packages
        WHERE organization_id = v_shipment.organization_id
          AND shipment_id = v_shipment.shipment_id
          AND status_code <> 'voided'
          AND status_code <> 'shipped';

        IF v_unready_package_count > 0 THEN
            RAISE EXCEPTION
                'Shipment % cannot become shipped because % active package(s) are not shipped',
                p_shipment_id,
                v_unready_package_count
                USING ERRCODE = 'P0001';
        END IF;

    END IF;

    /*
     * Internal actors must be active members of the
     * shipment organization.
     */
    IF p_performed_by_user_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM public.organization_users ou
           WHERE ou.organization_id = v_shipment.organization_id
             AND ou.user_id = p_performed_by_user_id
             AND ou.is_active = TRUE
       ) THEN
        RAISE EXCEPTION
            'User % is not an active member of organization %',
            p_performed_by_user_id,
            v_shipment.organization_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Use one timestamp for both the shipment state change
     * and its immutable history event.
     */
    v_event_at := CURRENT_TIMESTAMP;

    /*
     * Update shipment state.
     */
    UPDATE fulfillment.shipments
    SET
        status_code = p_new_status_code,

        shipped_at =
            CASE
                WHEN p_new_status_code = 'shipped'
                    THEN v_event_at
                ELSE NULL
            END,

        updated_at = v_event_at

    WHERE shipment_id = v_shipment.shipment_id
    RETURNING *
    INTO v_updated_shipment;

    /*
     * Append immutable shipment history.
     */
    INSERT INTO fulfillment.shipment_events (
        organization_id,
        shipment_id,
        event_type,
        previous_status_code,
        new_status_code,
        reason,
        metadata,
        performed_by_user_id,
        event_at
    )
    VALUES (
        v_shipment.organization_id,
        v_shipment.shipment_id,
        'status_changed',
        v_previous_status_code,
        p_new_status_code,
        p_reason,
        COALESCE(p_metadata, '{}'::jsonb),
        p_performed_by_user_id,
        v_event_at
    );

    RETURN v_updated_shipment;
END;
$function$;
--------------------------------------------------

------------------------------------------------------------------
-------------function fulfillment.protect_package_contents
------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fulfillment.protect_package_contents()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_package_status VARCHAR(30);
    v_package_id BIGINT;
    v_organization_id INTEGER;
    v_shipment_id BIGINT;
BEGIN
    /*
     * Determine which package owns the content row.
     *
     * INSERT uses NEW.
     * DELETE uses OLD.
     * UPDATE protects the existing package represented by OLD.
     */
    IF TG_OP = 'INSERT' THEN
        v_package_id := NEW.package_id;
        v_organization_id := NEW.organization_id;
        v_shipment_id := NEW.shipment_id;
    ELSE
        v_package_id := OLD.package_id;
        v_organization_id := OLD.organization_id;
        v_shipment_id := OLD.shipment_id;
    END IF;

    /*
     * Lock the package while validating its physical state.
     */
    SELECT p.status_code
    INTO v_package_status
    FROM fulfillment.packages p
    WHERE p.organization_id = v_organization_id
      AND p.shipment_id = v_shipment_id
      AND p.package_id = v_package_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Package % does not exist for shipment % in organization %',
            v_package_id,
            v_shipment_id,
            v_organization_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Package contents may only change while the package
     * remains physically open.
     */
    IF v_package_status <> 'open' THEN
        RAISE EXCEPTION
            'Package contents cannot be modified when package % is in status %. Package must be open',
            v_package_id,
            v_package_status
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * If an UPDATE attempts to move the content row to another
     * package, the destination package must also be open.
     *
     * Existing foreign keys continue to enforce organization /
     * shipment / package relationships.
     */
    IF TG_OP = 'UPDATE'
       AND (
            NEW.package_id IS DISTINCT FROM OLD.package_id
            OR NEW.organization_id IS DISTINCT FROM OLD.organization_id
            OR NEW.shipment_id IS DISTINCT FROM OLD.shipment_id
       ) THEN

        SELECT p.status_code
        INTO v_package_status
        FROM fulfillment.packages p
        WHERE p.organization_id = NEW.organization_id
          AND p.shipment_id = NEW.shipment_id
          AND p.package_id = NEW.package_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Destination package % does not exist for shipment % in organization %',
                NEW.package_id,
                NEW.shipment_id,
                NEW.organization_id
                USING ERRCODE = 'P0002';
        END IF;

        IF v_package_status <> 'open' THEN
            RAISE EXCEPTION
                'Package contents cannot be moved to package % because it is in status %. Package must be open',
                NEW.package_id,
                v_package_status
                USING ERRCODE = 'P0001';
        END IF;

    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;
--------------------------------------------------------------------
------------------- trigger protect package contents
--------------------------------------------------------------------

CREATE TRIGGER trg_protect_package_contents
BEFORE INSERT OR UPDATE OR DELETE
ON fulfillment.package_contents
FOR EACH ROW
EXECUTE FUNCTION fulfillment.protect_package_contents();

------------------------------------------------------------------------
-------------------------- function fulfillment protect shipment items
------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.protect_shipment_items()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_shipment_status VARCHAR(30);
    v_shipment_id BIGINT;
    v_organization_id INTEGER;
BEGIN
    /*
     * Determine the current parent shipment.
     *
     * INSERT uses NEW.
     * UPDATE and DELETE protect the shipment represented by OLD.
     */
    IF TG_OP = 'INSERT' THEN
        v_shipment_id := NEW.shipment_id;
        v_organization_id := NEW.organization_id;
    ELSE
        v_shipment_id := OLD.shipment_id;
        v_organization_id := OLD.organization_id;
    END IF;

    /*
     * Lock the parent shipment while validating its state.
     */
    SELECT s.status_code
    INTO v_shipment_status
    FROM fulfillment.shipments s
    WHERE s.organization_id = v_organization_id
      AND s.shipment_id = v_shipment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Shipment % does not exist in organization %',
            v_shipment_id,
            v_organization_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Shipment items may only change while the shipment
     * remains pending.
     */
    IF v_shipment_status <> 'pending' THEN
        RAISE EXCEPTION
            'Shipment items cannot be modified when shipment % is in status %. Shipment must be pending',
            v_shipment_id,
            v_shipment_status
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * If an UPDATE attempts to move the item to another
     * shipment, the destination shipment must also be pending.
     */
    IF TG_OP = 'UPDATE'
       AND (
            NEW.shipment_id IS DISTINCT FROM OLD.shipment_id
            OR NEW.organization_id IS DISTINCT FROM OLD.organization_id
       ) THEN

        SELECT s.status_code
        INTO v_shipment_status
        FROM fulfillment.shipments s
        WHERE s.organization_id = NEW.organization_id
          AND s.shipment_id = NEW.shipment_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Destination shipment % does not exist in organization %',
                NEW.shipment_id,
                NEW.organization_id
                USING ERRCODE = 'P0002';
        END IF;

        IF v_shipment_status <> 'pending' THEN
            RAISE EXCEPTION
                'Shipment items cannot be moved to shipment % because it is in status %. Shipment must be pending',
                NEW.shipment_id,
                v_shipment_status
                USING ERRCODE = 'P0001';
        END IF;

    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;
-----------------------------------------------------------
--------------- trigger protect shipment items
----------------------------------------------------------

CREATE TRIGGER trg_protect_shipment_items
BEFORE INSERT OR UPDATE OR DELETE
ON fulfillment.shipment_items
FOR EACH ROW
EXECUTE FUNCTION fulfillment.protect_shipment_items();

--------------------------------------------------------
----------------- view returns delivered item quantities
--------------------------------------------------------

CREATE OR REPLACE VIEW returns.delivered_item_quantities AS

SELECT
    so.organization_id,

    soi.sales_order_id,
    soi.sales_order_item_id,
    soi.variant_id,

    foi.fulfillment_order_id,
    foi.fulfillment_order_item_id,

    si.shipment_id,
    si.shipment_item_id,

    pc.package_id,
    pc.package_content_id,

    pc.quantity AS delivered_quantity,
    p.delivered_at

FROM public.sales_order_items soi

JOIN public.sales_orders so
    ON so.sales_order_id = soi.sales_order_id

JOIN fulfillment.fulfillment_order_items foi
    ON foi.sales_order_item_id = soi.sales_order_item_id

JOIN fulfillment.fulfillment_orders fo
    ON fo.organization_id = so.organization_id
   AND fo.fulfillment_order_id = foi.fulfillment_order_id
   AND fo.sales_order_id = soi.sales_order_id

JOIN fulfillment.shipment_items si
    ON si.organization_id = fo.organization_id
   AND si.fulfillment_order_id = foi.fulfillment_order_id
   AND si.fulfillment_order_item_id = foi.fulfillment_order_item_id

JOIN fulfillment.package_contents pc
    ON pc.organization_id = si.organization_id
   AND pc.shipment_id = si.shipment_id
   AND pc.shipment_item_id = si.shipment_item_id

JOIN fulfillment.packages p
    ON p.organization_id = pc.organization_id
   AND p.shipment_id = pc.shipment_id
   AND p.package_id = pc.package_id

WHERE p.delivery_status_code = 'delivered'
  AND p.delivered_at IS NOT NULL;
------------------------------------------------------
------------- returns return policies 
------------------------------------------------------

CREATE TABLE returns.return_policies (
    return_policy_id BIGINT
        GENERATED BY DEFAULT AS IDENTITY
        PRIMARY KEY,

    organization_id INTEGER NOT NULL,

    policy_code VARCHAR(50) NOT NULL,
    policy_name VARCHAR(100) NOT NULL,
    description TEXT,

    is_returnable BOOLEAN NOT NULL DEFAULT TRUE,

    return_window_days INTEGER,

    requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
    requires_inspection BOOLEAN NOT NULL DEFAULT TRUE,

    allow_opened BOOLEAN NOT NULL DEFAULT TRUE,
    allow_partial_return BOOLEAN NOT NULL DEFAULT TRUE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT return_policies_organization_fk
        FOREIGN KEY (organization_id)
        REFERENCES public.organizations(organization_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT uq_return_policies_org_code
        UNIQUE (organization_id, policy_code),

    CONSTRAINT uq_return_policies_org_policy
        UNIQUE (organization_id, return_policy_id),

    CONSTRAINT return_policies_code_not_blank
        CHECK (btrim(policy_code) <> ''),

    CONSTRAINT return_policies_code_format
        CHECK (
            policy_code ~ '^[A-Z][A-Z0-9_]*$'
        ),

    CONSTRAINT return_policies_name_not_blank
        CHECK (btrim(policy_name) <> ''),

    CONSTRAINT return_policies_description_not_blank
        CHECK (
            description IS NULL
            OR btrim(description) <> ''
        ),

    CONSTRAINT return_policies_window_valid
        CHECK (
            (
                is_returnable = TRUE
                AND return_window_days IS NOT NULL
                AND return_window_days > 0
            )
            OR
            (
                is_returnable = FALSE
                AND (
                    return_window_days IS NULL
                    OR return_window_days > 0
                )
            )
        )
);
---------------------------------------------------
----------- create table product return policies
---------------------------------------------------
CREATE TABLE returns.product_return_policies (
    organization_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    return_policy_id BIGINT NOT NULL,

    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT product_return_policies_pkey
        PRIMARY KEY (
            organization_id,
            product_id
        ),

    CONSTRAINT product_return_policies_product_fk
        FOREIGN KEY (
            organization_id,
            product_id
        )
        REFERENCES public.products (
            organization_id,
            product_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT product_return_policies_policy_fk
        FOREIGN KEY (
            organization_id,
            return_policy_id
        )
        REFERENCES returns.return_policies (
            organization_id,
            return_policy_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
---------------------------------------------------
-------- table returns variants returns
---------------------------------------------------
CREATE TABLE returns.variant_return_policies (
    organization_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    return_policy_id BIGINT NOT NULL,

    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT variant_return_policies_pkey
        PRIMARY KEY (
            organization_id,
            variant_id
        ),

    /*
     * Proves that the product belongs to the organization.
     */
    CONSTRAINT variant_return_policies_product_fk
        FOREIGN KEY (
            organization_id,
            product_id
        )
        REFERENCES public.products (
            organization_id,
            product_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    /*
     * Proves that the variant actually belongs to that product.
     */
    CONSTRAINT variant_return_policies_variant_fk
        FOREIGN KEY (
            product_id,
            variant_id
        )
        REFERENCES public.product_variants (
            product_id,
            variant_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    /*
     * Prevents using another organization's return policy.
     */
    CONSTRAINT variant_return_policies_policy_fk
        FOREIGN KEY (
            organization_id,
            return_policy_id
        )
        REFERENCES returns.return_policies (
            organization_id,
            return_policy_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
----------------------------------------------------
------- view resolved variant return policy
----------------------------------------------------

CREATE VIEW returns.resolved_variant_return_policies AS
SELECT
    p.organization_id,
    p.product_id,
    p.name AS product_name,

    pv.variant_id,
    pv.sku,

    prp.return_policy_id AS product_policy_id,
    vrp.return_policy_id AS variant_policy_id,

    COALESCE(
        vrp.return_policy_id,
        prp.return_policy_id
    ) AS resolved_policy_id,

    CASE
        WHEN vrp.return_policy_id IS NOT NULL THEN 'VARIANT'
        WHEN prp.return_policy_id IS NOT NULL THEN 'PRODUCT'
        ELSE 'NOT_CONFIGURED'
    END AS policy_source,

    rp.policy_code,
    rp.policy_name,
    rp.description,
    rp.is_returnable,
    rp.return_window_days,
    rp.requires_approval,
    rp.requires_inspection,
    rp.allow_opened,
    rp.allow_partial_return,
    rp.is_active AS policy_is_active

FROM public.products p

JOIN public.product_variants pv
    ON pv.product_id = p.product_id

LEFT JOIN returns.product_return_policies prp
    ON prp.organization_id = p.organization_id
   AND prp.product_id = p.product_id

LEFT JOIN returns.variant_return_policies vrp
    ON vrp.organization_id = p.organization_id
   AND vrp.product_id = p.product_id
   AND vrp.variant_id = pv.variant_id

LEFT JOIN returns.return_policies rp
    ON rp.organization_id = p.organization_id
   AND rp.return_policy_id = COALESCE(
       vrp.return_policy_id,
       prp.return_policy_id
   );
------------------------------------------------
---------------
------------------------------------------------