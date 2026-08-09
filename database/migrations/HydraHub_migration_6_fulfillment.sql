-- migration 6 -- fulfillment 
-------------------------------------
BEGIN;

CREATE SCHEMA fulfillment;

CREATE TABLE fulfillment.fulfillment_statuses (
    status_code varchar(30) PRIMARY KEY,
    display_name varchar(50) NOT NULL,
    description text,
    is_terminal boolean NOT NULL,
    sort_order smallint NOT NULL,

    CONSTRAINT fulfillment_statuses_status_code_format
        CHECK (
            status_code = lower(status_code)
            AND status_code ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT fulfillment_statuses_display_name_not_blank
        CHECK (btrim(display_name) <> ''),

    CONSTRAINT fulfillment_statuses_sort_order_positive
        CHECK (sort_order > 0),

    CONSTRAINT fulfillment_statuses_sort_order_unique
        UNIQUE (sort_order)
);

CREATE TABLE fulfillment.pick_statuses (
    status_code varchar(30) PRIMARY KEY,
    display_name varchar(50) NOT NULL,
    description text,
    is_terminal boolean NOT NULL,
    sort_order smallint NOT NULL,

    CONSTRAINT pick_statuses_status_code_format
        CHECK (
            status_code = lower(status_code)
            AND status_code ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT pick_statuses_display_name_not_blank
        CHECK (btrim(display_name) <> ''),

    CONSTRAINT pick_statuses_sort_order_positive
        CHECK (sort_order > 0),

    CONSTRAINT pick_statuses_sort_order_unique
        UNIQUE (sort_order)
);

CREATE TABLE fulfillment.package_statuses (
    status_code varchar(30) PRIMARY KEY,
    display_name varchar(50) NOT NULL,
    description text,
    is_terminal boolean NOT NULL,
    sort_order smallint NOT NULL,

    CONSTRAINT package_statuses_status_code_format
        CHECK (
            status_code = lower(status_code)
            AND status_code ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT package_statuses_display_name_not_blank
        CHECK (btrim(display_name) <> ''),

    CONSTRAINT package_statuses_sort_order_positive
        CHECK (sort_order > 0),

    CONSTRAINT package_statuses_sort_order_unique
        UNIQUE (sort_order)
);

CREATE TABLE fulfillment.shipment_statuses (
    status_code varchar(30) PRIMARY KEY,
    display_name varchar(50) NOT NULL,
    description text,
    is_terminal boolean NOT NULL,
    sort_order smallint NOT NULL,

    CONSTRAINT shipment_statuses_status_code_format
        CHECK (
            status_code = lower(status_code)
            AND status_code ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT shipment_statuses_display_name_not_blank
        CHECK (btrim(display_name) <> ''),

    CONSTRAINT shipment_statuses_sort_order_positive
        CHECK (sort_order > 0),

    CONSTRAINT shipment_statuses_sort_order_unique
        UNIQUE (sort_order)
);

INSERT INTO fulfillment.fulfillment_statuses (
    status_code,
    display_name,
    description,
    is_terminal,
    sort_order
)
VALUES
    (
        'pending',
        'Pending',
        'The fulfillment order has been created but warehouse processing has not started.',
        false,
        10
    ),
    (
        'partially_reserved',
        'Partially Reserved',
        'Some, but not all, assigned inventory has been reserved.',
        false,
        20
    ),
    (
        'reserved',
        'Reserved',
        'All inventory assigned to the fulfillment order is reserved.',
        false,
        30
    ),
    (
        'picking',
        'Picking',
        'Warehouse picking is in progress.',
        false,
        40
    ),
    (
        'partially_picked',
        'Partially Picked',
        'Some, but not all, required inventory has been picked.',
        false,
        50
    ),
    (
        'picked',
        'Picked',
        'All inventory required for the fulfillment order has been picked.',
        false,
        60
    ),
    (
        'packing',
        'Packing',
        'Packing is in progress.',
        false,
        70
    ),
    (
        'partially_packed',
        'Partially Packed',
        'Some, but not all, picked inventory has been packed.',
        false,
        80
    ),
    (
        'packed',
        'Packed',
        'All inventory currently intended for shipment has been packed.',
        false,
        90
    ),
    (
        'partially_shipped',
        'Partially Shipped',
        'Some, but not all, assigned quantities have shipped.',
        false,
        100
    ),
    (
        'shipped',
        'Shipped',
        'All non-cancelled quantities assigned to the fulfillment order have shipped.',
        true,
        110
    ),
    (
        'cancelled',
        'Cancelled',
        'The fulfillment order was cancelled before completion.',
        true,
        120
    );

INSERT INTO fulfillment.pick_statuses (
    status_code,
    display_name,
    description,
    is_terminal,
    sort_order
)
VALUES
    (
        'pending',
        'Pending',
        'The pick has been created but has not started.',
        false,
        10
    ),
    (
        'in_progress',
        'In Progress',
        'Warehouse picking is currently in progress.',
        false,
        20
    ),
    (
        'completed',
        'Completed',
        'The pick has been completed.',
        true,
        30
    ),
    (
        'cancelled',
        'Cancelled',
        'The pick was cancelled.',
        true,
        40
    );

INSERT INTO fulfillment.package_statuses (
    status_code,
    display_name,
    description,
    is_terminal,
    sort_order
)
VALUES
    (
        'open',
        'Open',
        'The package is open and its contents may still be changed.',
        false,
        10
    ),
    (
        'sealed',
        'Sealed',
        'The package has been sealed and its contents are fixed.',
        false,
        20
    ),
    (
        'shipped',
        'Shipped',
        'The package has been included in a confirmed shipment.',
        true,
        30
    ),
    (
        'voided',
        'Voided',
        'The package was voided and cannot be shipped.',
        true,
        40
    );

INSERT INTO fulfillment.shipment_statuses (
    status_code,
    display_name,
    description,
    is_terminal,
    sort_order
)
VALUES
    (
        'pending',
        'Pending',
        'The shipment has been created but is not ready for confirmation.',
        false,
        10
    ),
    (
        'ready',
        'Ready',
        'The shipment has valid sealed packages and may be confirmed.',
        false,
        20
    ),
    (
        'shipped',
        'Shipped',
        'The shipment has been confirmed and inventory has been consumed.',
        true,
        30
    ),
    (
        'cancelled',
        'Cancelled',
        'The shipment was cancelled before confirmation.',
        true,
        40
    );

COMMIT;

--------------------------------------
------------ fulfillment orders 
--------------------------------------

BEGIN;

-- ============================================================
-- Supporting composite keys
-- ============================================================
-- These allow organization-safe foreign keys from fulfillment
-- orders to sales orders and warehouses.

ALTER TABLE public.sales_orders
    ADD CONSTRAINT sales_orders_organization_order_unique
    UNIQUE (organization_id, sales_order_id);

ALTER TABLE public.warehouses
    ADD CONSTRAINT warehouses_organization_warehouse_unique
    UNIQUE (organization_id, warehouse_id);

-- This supports a protected composite reference from a
-- fulfillment item to the original sales-order item and variant.
ALTER TABLE public.sales_order_items
    ADD CONSTRAINT sales_order_items_item_variant_unique
    UNIQUE (sales_order_item_id, variant_id);


-- ============================================================
-- Fulfillment orders
-- ============================================================

CREATE TABLE fulfillment.fulfillment_orders (
    fulfillment_order_id bigint GENERATED BY DEFAULT AS IDENTITY,
    fulfillment_number varchar(30) NOT NULL,

    organization_id integer NOT NULL,
    sales_order_id integer NOT NULL,
    warehouse_id integer NOT NULL,

    status_code varchar(30) NOT NULL DEFAULT 'pending',

    priority smallint NOT NULL DEFAULT 100,
    requested_ship_date date,

    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    cancelled_at timestamp without time zone,

    created_by_user_id integer,

    created_at timestamp without time zone
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at timestamp without time zone
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    metadata jsonb,

    CONSTRAINT fulfillment_orders_pkey
        PRIMARY KEY (fulfillment_order_id),

    CONSTRAINT fulfillment_orders_organization_number_unique
        UNIQUE (organization_id, fulfillment_number),

    CONSTRAINT fulfillment_orders_fulfillment_number_not_blank
        CHECK (btrim(fulfillment_number) <> ''),

    CONSTRAINT fulfillment_orders_fulfillment_number_format
        CHECK (
            fulfillment_number =
                upper(fulfillment_number)
            AND fulfillment_number ~
                '^[A-Z][A-Z0-9_-]*$'
        ),

    CONSTRAINT fulfillment_orders_priority_positive
        CHECK (priority > 0),

    CONSTRAINT fulfillment_orders_started_not_before_created
        CHECK (
            started_at IS NULL
            OR started_at >= created_at
        ),

    CONSTRAINT fulfillment_orders_completed_not_before_created
        CHECK (
            completed_at IS NULL
            OR completed_at >= created_at
        ),

    CONSTRAINT fulfillment_orders_cancelled_not_before_created
        CHECK (
            cancelled_at IS NULL
            OR cancelled_at >= created_at
        ),

    CONSTRAINT fulfillment_orders_updated_not_before_created
        CHECK (updated_at >= created_at),

    CONSTRAINT fulfillment_orders_single_terminal_timestamp
        CHECK (
            num_nonnulls(
                completed_at,
                cancelled_at
            ) <= 1
        ),

    CONSTRAINT fulfillment_orders_status_timestamp_consistency
        CHECK (
            (
                status_code = 'shipped'
                AND completed_at IS NOT NULL
                AND cancelled_at IS NULL
            )
            OR
            (
                status_code = 'cancelled'
                AND cancelled_at IS NOT NULL
                AND completed_at IS NULL
            )
            OR
            (
                status_code NOT IN (
                    'shipped',
                    'cancelled'
                )
                AND completed_at IS NULL
                AND cancelled_at IS NULL
            )
        ),

    CONSTRAINT fulfillment_orders_status_code_fkey
        FOREIGN KEY (status_code)
        REFERENCES fulfillment.fulfillment_statuses(status_code)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT fulfillment_orders_organization_sales_order_fkey
        FOREIGN KEY (
            organization_id,
            sales_order_id
        )
        REFERENCES public.sales_orders(
            organization_id,
            sales_order_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT fulfillment_orders_organization_warehouse_fkey
        FOREIGN KEY (
            organization_id,
            warehouse_id
        )
        REFERENCES public.warehouses(
            organization_id,
            warehouse_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT fulfillment_orders_created_by_user_fkey
        FOREIGN KEY (created_by_user_id)
        REFERENCES public.users(user_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);


-- ============================================================
-- Fulfillment-order items
-- ============================================================

CREATE TABLE fulfillment.fulfillment_order_items (
    fulfillment_order_item_id bigint
        GENERATED BY DEFAULT AS IDENTITY,

    fulfillment_order_id bigint NOT NULL,

    sales_order_item_id integer NOT NULL,
    variant_id integer NOT NULL,

    requested_quantity integer NOT NULL,

    reserved_quantity integer NOT NULL DEFAULT 0,
    picked_quantity integer NOT NULL DEFAULT 0,
    packed_quantity integer NOT NULL DEFAULT 0,
    shipped_quantity integer NOT NULL DEFAULT 0,
    cancelled_quantity integer NOT NULL DEFAULT 0,

    created_at timestamp without time zone
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at timestamp without time zone
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    metadata jsonb,

    CONSTRAINT fulfillment_order_items_pkey
        PRIMARY KEY (fulfillment_order_item_id),

    CONSTRAINT fulfillment_order_items_order_sales_item_unique
        UNIQUE (
            fulfillment_order_id,
            sales_order_item_id
        ),

    CONSTRAINT fulfillment_order_items_requested_positive
        CHECK (requested_quantity > 0),

    CONSTRAINT fulfillment_order_items_reserved_nonnegative
        CHECK (reserved_quantity >= 0),

    CONSTRAINT fulfillment_order_items_picked_nonnegative
        CHECK (picked_quantity >= 0),

    CONSTRAINT fulfillment_order_items_packed_nonnegative
        CHECK (packed_quantity >= 0),

    CONSTRAINT fulfillment_order_items_shipped_nonnegative
        CHECK (shipped_quantity >= 0),

    CONSTRAINT fulfillment_order_items_cancelled_nonnegative
        CHECK (cancelled_quantity >= 0),

    /*
     * Active reservation quantity plus quantities already shipped
     * or cancelled cannot exceed the quantity assigned to this
     * fulfillment line.
     */
    CONSTRAINT fulfillment_order_items_inventory_coverage
        CHECK (
            reserved_quantity
            + shipped_quantity
            + cancelled_quantity
            <= requested_quantity
        ),

    CONSTRAINT fulfillment_order_items_picked_not_above_requested
        CHECK (
            picked_quantity + cancelled_quantity
            <= requested_quantity
        ),

    CONSTRAINT fulfillment_order_items_packed_not_above_picked
        CHECK (
            packed_quantity <= picked_quantity
        ),

    CONSTRAINT fulfillment_order_items_shipped_not_above_packed
        CHECK (
            shipped_quantity <= packed_quantity
        ),

    CONSTRAINT fulfillment_order_items_updated_not_before_created
        CHECK (updated_at >= created_at),

    CONSTRAINT fulfillment_order_items_order_fkey
        FOREIGN KEY (fulfillment_order_id)
        REFERENCES fulfillment.fulfillment_orders(
            fulfillment_order_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT fulfillment_order_items_sales_item_variant_fkey
        FOREIGN KEY (
            sales_order_item_id,
            variant_id
        )
        REFERENCES public.sales_order_items(
            sales_order_item_id,
            variant_id
        )
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);


-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_fulfillment_orders_organization_id
    ON fulfillment.fulfillment_orders(organization_id);

CREATE INDEX idx_fulfillment_orders_sales_order_id
    ON fulfillment.fulfillment_orders(sales_order_id);

CREATE INDEX idx_fulfillment_orders_warehouse_id
    ON fulfillment.fulfillment_orders(warehouse_id);

CREATE INDEX idx_fulfillment_orders_status_code
    ON fulfillment.fulfillment_orders(status_code);

CREATE INDEX idx_fulfillment_orders_requested_ship_date
    ON fulfillment.fulfillment_orders(requested_ship_date)
    WHERE requested_ship_date IS NOT NULL;

CREATE INDEX idx_fulfillment_order_items_order_id
    ON fulfillment.fulfillment_order_items(
        fulfillment_order_id
    );

CREATE INDEX idx_fulfillment_order_items_sales_item_id
    ON fulfillment.fulfillment_order_items(
        sales_order_item_id
    );

CREATE INDEX idx_fulfillment_order_items_variant_id
    ON fulfillment.fulfillment_order_items(
        variant_id
    );

COMMIT;

-----------------------------------------------------
----------fulfillment.create_fulfillment_order()
-----------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.create_fulfillment_order(
    p_sales_order_id integer,
    p_warehouse_id integer,
    p_items jsonb,
    p_requested_ship_date date DEFAULT NULL,
    p_priority smallint DEFAULT 100,
    p_created_by_user_id integer DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS fulfillment.fulfillment_orders
LANGUAGE plpgsql
VOLATILE
PARALLEL UNSAFE
AS $BODY$
DECLARE
    v_sales_order public.sales_orders%ROWTYPE;
    v_fulfillment_order fulfillment.fulfillment_orders%ROWTYPE;

    v_warehouse_organization_id integer;
    v_warehouse_is_active boolean;

    v_input_item_count integer;
    v_distinct_item_count integer;
    v_matching_item_count integer;

    v_invalid_item_id integer;
    v_invalid_requested_quantity integer;
    v_overallocated_item_id integer;
    v_order_quantity integer;
    v_existing_allocated_quantity integer;
    v_new_requested_quantity integer;
BEGIN
    /*
     * Validate scalar parameters.
     */
    IF p_sales_order_id IS NULL THEN
        RAISE EXCEPTION
            'sales_order_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_sales_order_id <= 0 THEN
        RAISE EXCEPTION
            'sales_order_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_warehouse_id IS NULL THEN
        RAISE EXCEPTION
            'warehouse_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_warehouse_id <= 0 THEN
        RAISE EXCEPTION
            'warehouse_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_priority IS NULL OR p_priority <= 0 THEN
        RAISE EXCEPTION
            'priority must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_items IS NULL THEN
        RAISE EXCEPTION
            'items are required'
            USING ERRCODE = '22004';
    END IF;

    IF jsonb_typeof(p_items) <> 'array' THEN
        RAISE EXCEPTION
            'items must be a JSON array'
            USING ERRCODE = '22023';
    END IF;

    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION
            'items must contain at least one fulfillment item'
            USING ERRCODE = '22023';
    END IF;

    IF p_metadata IS NOT NULL
       AND jsonb_typeof(p_metadata) <> 'object' THEN
        RAISE EXCEPTION
            'metadata must be a JSON object when supplied'
            USING ERRCODE = '22023';
    END IF;

    /*
     * Every array element must be a JSON object.
     */
    IF EXISTS (
        SELECT 1
        FROM jsonb_array_elements(p_items) AS item(value)
        WHERE jsonb_typeof(item.value) <> 'object'
    ) THEN
        RAISE EXCEPTION
            'every items array element must be a JSON object'
            USING ERRCODE = '22023';
    END IF;

    /*
     * Parse and validate the requested fulfillment lines.
     *
     * jsonb_to_recordset also rejects values that cannot be converted
     * to the declared integer columns.
     */
    SELECT
        COUNT(*),
        COUNT(DISTINCT parsed.sales_order_item_id)
    INTO
        v_input_item_count,
        v_distinct_item_count
    FROM jsonb_to_recordset(p_items) AS parsed(
        sales_order_item_id integer,
        requested_quantity integer
    );

    IF v_input_item_count <> v_distinct_item_count THEN
        RAISE EXCEPTION
            'items cannot contain duplicate sales_order_item_id values'
            USING ERRCODE = '22023';
    END IF;

    SELECT
        parsed.sales_order_item_id,
        parsed.requested_quantity
    INTO
        v_invalid_item_id,
        v_invalid_requested_quantity
    FROM jsonb_to_recordset(p_items) AS parsed(
        sales_order_item_id integer,
        requested_quantity integer
    )
    WHERE parsed.sales_order_item_id IS NULL
       OR parsed.sales_order_item_id <= 0
       OR parsed.requested_quantity IS NULL
       OR parsed.requested_quantity <= 0
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION
            'Invalid fulfillment item. sales_order_item_id: %, requested_quantity: %. Both values must be greater than zero',
            v_invalid_item_id,
            v_invalid_requested_quantity
            USING ERRCODE = '22023';
    END IF;

    /*
     * Lock the sales order so it cannot be cancelled or otherwise moved
     * into an incompatible state while fulfillment is being created.
     */
    SELECT *
    INTO v_sales_order
    FROM public.sales_orders
    WHERE sales_order_id = p_sales_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Sales order % does not exist',
            p_sales_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Terminal and blocked sales orders cannot receive new warehouse
     * fulfillment assignments.
     *
     * PAID is retained because it is an existing legacy order status.
     */
    IF v_sales_order.status IN (
        'SHIPPED',
        'FULFILLED',
        'CANCELLED',
        'ON_HOLD'
    ) THEN
        RAISE EXCEPTION
            'Sales order % cannot enter fulfillment because its current status is %',
            p_sales_order_id,
            v_sales_order.status
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Validate and lock the warehouse.
     */
    SELECT
        organization_id,
        is_active
    INTO
        v_warehouse_organization_id,
        v_warehouse_is_active
    FROM public.warehouses
    WHERE warehouse_id = p_warehouse_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Warehouse % does not exist',
            p_warehouse_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_warehouse_is_active IS NOT TRUE THEN
        RAISE EXCEPTION
            'Warehouse % is inactive',
            p_warehouse_id
            USING ERRCODE = 'P0001';
    END IF;

    IF v_warehouse_organization_id <>
       v_sales_order.organization_id THEN
        RAISE EXCEPTION
            'Warehouse % belongs to organization %, but sales order % belongs to organization %',
            p_warehouse_id,
            v_warehouse_organization_id,
            p_sales_order_id,
            v_sales_order.organization_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock all referenced sales-order items in deterministic order.
     * This prevents two concurrent fulfillment requests from assigning
     * the same remaining order quantity.
     */
    PERFORM soi.sales_order_item_id
    FROM public.sales_order_items soi
    JOIN jsonb_to_recordset(p_items) AS parsed(
        sales_order_item_id integer,
        requested_quantity integer
    )
        ON parsed.sales_order_item_id =
           soi.sales_order_item_id
    WHERE soi.sales_order_id = p_sales_order_id
    ORDER BY soi.sales_order_item_id
    FOR UPDATE OF soi;

    /*
     * Confirm that every supplied item belongs to this sales order.
     */
    SELECT COUNT(*)
    INTO v_matching_item_count
    FROM public.sales_order_items soi
    JOIN jsonb_to_recordset(p_items) AS parsed(
        sales_order_item_id integer,
        requested_quantity integer
    )
        ON parsed.sales_order_item_id =
           soi.sales_order_item_id
    WHERE soi.sales_order_id = p_sales_order_id;

    IF v_matching_item_count <> v_input_item_count THEN
        SELECT parsed.sales_order_item_id
        INTO v_invalid_item_id
        FROM jsonb_to_recordset(p_items) AS parsed(
            sales_order_item_id integer,
            requested_quantity integer
        )
        LEFT JOIN public.sales_order_items soi
            ON soi.sales_order_item_id =
               parsed.sales_order_item_id
           AND soi.sales_order_id =
               p_sales_order_id
        WHERE soi.sales_order_item_id IS NULL
        LIMIT 1;

        RAISE EXCEPTION
            'Sales-order item % does not exist on sales order %',
            v_invalid_item_id,
            p_sales_order_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Prevent assignment above the remaining sales-order quantity.
     *
     * Existing allocation is:
     *     requested_quantity - cancelled_quantity
     *
     * Fulfilled quantities remain allocated because they already
     * satisfied part of the original sales-order demand.
     */
    SELECT
        soi.sales_order_item_id,
        soi.quantity,
        COALESCE(
            SUM(
                foi.requested_quantity -
                foi.cancelled_quantity
            ),
            0
        )::integer,
        parsed.requested_quantity
    INTO
        v_overallocated_item_id,
        v_order_quantity,
        v_existing_allocated_quantity,
        v_new_requested_quantity
    FROM public.sales_order_items soi
    JOIN jsonb_to_recordset(p_items) AS parsed(
        sales_order_item_id integer,
        requested_quantity integer
    )
        ON parsed.sales_order_item_id =
           soi.sales_order_item_id
    LEFT JOIN fulfillment.fulfillment_order_items foi
        ON foi.sales_order_item_id =
           soi.sales_order_item_id
    WHERE soi.sales_order_id = p_sales_order_id
    GROUP BY
        soi.sales_order_item_id,
        soi.quantity,
        parsed.requested_quantity
    HAVING
        COALESCE(
            SUM(
                foi.requested_quantity -
                foi.cancelled_quantity
            ),
            0
        )
        + parsed.requested_quantity
        > soi.quantity
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION
            'Fulfillment assignment exceeds sales-order item %. Ordered: %, already allocated: %, new requested: %, remaining assignable: %',
            v_overallocated_item_id,
            v_order_quantity,
            v_existing_allocated_quantity,
            v_new_requested_quantity,
            v_order_quantity -
                v_existing_allocated_quantity
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Create the fulfillment-order header.
     * fulfillment_number is generated by the column default.
     */
    INSERT INTO fulfillment.fulfillment_orders (
        organization_id,
        sales_order_id,
        warehouse_id,
        status_code,
        priority,
        requested_ship_date,
        created_by_user_id,
        metadata
    )
    VALUES (
        v_sales_order.organization_id,
        p_sales_order_id,
        p_warehouse_id,
        'pending',
        p_priority,
        p_requested_ship_date,
        p_created_by_user_id,
        p_metadata
    )
    RETURNING *
    INTO v_fulfillment_order;

    /*
     * Create all fulfillment-order items atomically.
     *
     * variant_id is copied from the authoritative sales-order item
     * instead of being accepted from the caller.
     */
    INSERT INTO fulfillment.fulfillment_order_items (
        fulfillment_order_id,
        sales_order_item_id,
        variant_id,
        requested_quantity
    )
    SELECT
        v_fulfillment_order.fulfillment_order_id,
        soi.sales_order_item_id,
        soi.variant_id,
        parsed.requested_quantity
    FROM jsonb_to_recordset(p_items) AS parsed(
        sales_order_item_id integer,
        requested_quantity integer
    )
    JOIN public.sales_order_items soi
        ON soi.sales_order_item_id =
           parsed.sales_order_item_id
       AND soi.sales_order_id =
           p_sales_order_id
    ORDER BY soi.sales_order_item_id;

	/*
     * Record the immutable creation event.
     */
    INSERT INTO fulfillment.fulfillment_events (
        organization_id,
        fulfillment_order_id,
        event_type,
        previous_status_code,
        new_status_code,
        performed_by_user_id,
        metadata
    )
    VALUES (
        v_fulfillment_order.organization_id,
        v_fulfillment_order.fulfillment_order_id,
        'created',
        NULL,
        v_fulfillment_order.status_code,
        p_created_by_user_id,
        jsonb_build_object(
            'sales_order_id', p_sales_order_id,
            'warehouse_id', p_warehouse_id,
            'item_count', jsonb_array_length(p_items)
        )
        ||
        COALESCE(
            p_metadata,
            '{}'::jsonb
        )
    );

    RETURN v_fulfillment_order;
END;
$BODY$;

ALTER FUNCTION fulfillment.create_fulfillment_order(
    integer,
    integer,
    jsonb,
    date,
    smallint,
    integer,
    jsonb
)
OWNER TO jos;
---------------------------------------------
----fulfillment.fulfillment_events
----------------------------------------------

BEGIN;

-- ============================================================
-- Supporting composite keys
-- ============================================================
-- These let the event table enforce that an item belongs to the
-- fulfillment order recorded on the same event.

ALTER TABLE fulfillment.fulfillment_orders
    ADD CONSTRAINT fulfillment_orders_org_order_unique
    UNIQUE (
        organization_id,
        fulfillment_order_id
    );

ALTER TABLE fulfillment.fulfillment_order_items
    ADD CONSTRAINT fulfillment_order_items_order_item_unique
    UNIQUE (
        fulfillment_order_id,
        fulfillment_order_item_id
    );


-- ============================================================
-- Immutable fulfillment event history
-- ============================================================

CREATE TABLE fulfillment.fulfillment_events (
    fulfillment_event_id bigint
        GENERATED BY DEFAULT AS IDENTITY,

    organization_id integer NOT NULL,
    fulfillment_order_id bigint NOT NULL,
    fulfillment_order_item_id bigint,

    reservation_id bigint,

    event_type varchar(50) NOT NULL,

    previous_status_code varchar(30),
    new_status_code varchar(30),

    previous_quantity integer,
    new_quantity integer,

    reason text,
    metadata jsonb,

    performed_by_user_id integer,

    event_at timestamp without time zone
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fulfillment_events_pkey
        PRIMARY KEY (fulfillment_event_id),

    CONSTRAINT fulfillment_events_event_type_not_blank
        CHECK (btrim(event_type) <> ''),

    CONSTRAINT fulfillment_events_event_type_format
        CHECK (
            event_type = lower(event_type)
            AND event_type ~ '^[a-z][a-z0-9_]*$'
        ),

    CONSTRAINT fulfillment_events_previous_status_format
        CHECK (
            previous_status_code IS NULL
            OR (
                previous_status_code =
                    lower(previous_status_code)
                AND previous_status_code ~
                    '^[a-z][a-z0-9_]*$'
            )
        ),

    CONSTRAINT fulfillment_events_new_status_format
        CHECK (
            new_status_code IS NULL
            OR (
                new_status_code =
                    lower(new_status_code)
                AND new_status_code ~
                    '^[a-z][a-z0-9_]*$'
            )
        ),

    CONSTRAINT fulfillment_events_previous_quantity_nonnegative
        CHECK (
            previous_quantity IS NULL
            OR previous_quantity >= 0
        ),

    CONSTRAINT fulfillment_events_new_quantity_nonnegative
        CHECK (
            new_quantity IS NULL
            OR new_quantity >= 0
        ),

    CONSTRAINT fulfillment_events_reason_not_blank
        CHECK (
            reason IS NULL
            OR btrim(reason) <> ''
        ),

    CONSTRAINT fulfillment_events_metadata_object
        CHECK (
            metadata IS NULL
            OR jsonb_typeof(metadata) = 'object'
        ),

    CONSTRAINT fulfillment_events_organization_order_fkey
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

    CONSTRAINT fulfillment_events_order_item_fkey
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

    CONSTRAINT fulfillment_events_reservation_fkey
        FOREIGN KEY (reservation_id)
        REFERENCES inventory.reservations(reservation_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT fulfillment_events_performed_by_user_fkey
        FOREIGN KEY (performed_by_user_id)
        REFERENCES public.users(user_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);


-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_fulfillment_events_order
    ON fulfillment.fulfillment_events (
        fulfillment_order_id,
        event_at
    );

CREATE INDEX idx_fulfillment_events_order_item
    ON fulfillment.fulfillment_events (
        fulfillment_order_item_id,
        event_at
    )
    WHERE fulfillment_order_item_id IS NOT NULL;

CREATE INDEX idx_fulfillment_events_reservation
    ON fulfillment.fulfillment_events (
        reservation_id,
        event_at
    )
    WHERE reservation_id IS NOT NULL;

CREATE INDEX idx_fulfillment_events_event_type
    ON fulfillment.fulfillment_events (
        event_type,
        event_at
    );

CREATE INDEX idx_fulfillment_events_performed_by
    ON fulfillment.fulfillment_events (
        performed_by_user_id,
        event_at
    )
    WHERE performed_by_user_id IS NOT NULL;


-- ============================================================
-- Immutability protection
-- ============================================================

CREATE OR REPLACE FUNCTION fulfillment.prevent_fulfillment_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $BODY$
BEGIN
    RAISE EXCEPTION
        'Fulfillment events are immutable and cannot be updated or deleted'
        USING ERRCODE = 'P0001';
END;
$BODY$;

CREATE TRIGGER trg_fulfillment_events_immutable
BEFORE UPDATE OR DELETE
ON fulfillment.fulfillment_events
FOR EACH ROW
EXECUTE FUNCTION fulfillment.prevent_fulfillment_event_mutation();

ALTER FUNCTION fulfillment.prevent_fulfillment_event_mutation()
    OWNER TO jos;

COMMIT;

-----------------------------------------------------------
-----------Reservation bridge function
-----------------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.reserve_fulfillment_order_item(
    p_fulfillment_order_item_id bigint,
    p_quantity integer,
    p_expires_at timestamp without time zone DEFAULT NULL,
    p_performed_by_user_id integer DEFAULT NULL,
    p_reason text DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS inventory.reservations
LANGUAGE plpgsql
AS $function$
DECLARE
    v_fulfillment_order_id bigint;
    v_order fulfillment.fulfillment_orders%ROWTYPE;
    v_item fulfillment.fulfillment_order_items%ROWTYPE;
    v_reservation inventory.reservations%ROWTYPE;

    v_warehouse_inventory_id integer;
    v_remaining_quantity integer;

    v_previous_status_code varchar(30);
    v_new_status_code varchar(30);

    v_total_requested bigint;
    v_total_reserved bigint;
    v_total_shipped bigint;
    v_total_cancelled bigint;
BEGIN
    /*
     * Validate parameters.
     */
    IF p_fulfillment_order_item_id IS NULL THEN
        RAISE EXCEPTION
            'fulfillment_order_item_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_fulfillment_order_item_id <= 0 THEN
        RAISE EXCEPTION
            'fulfillment_order_item_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION
            'Reservation quantity must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_expires_at IS NOT NULL
       AND p_expires_at <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION
            'expires_at must be later than the current timestamp'
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
     * Resolve the parent fulfillment order.
     */
    SELECT fulfillment_order_id
    INTO v_fulfillment_order_id
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id =
          p_fulfillment_order_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % does not exist',
            p_fulfillment_order_item_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Lock the parent order first.
     */
    SELECT *
    INTO v_order
    FROM fulfillment.fulfillment_orders
    WHERE fulfillment_order_id =
          v_fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment order % does not exist',
            v_fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Only fulfillment orders still in the reservation phase
     * may receive new inventory reservations.
     */
    IF v_order.status_code NOT IN (
        'pending',
        'partially_reserved'
    ) THEN
        RAISE EXCEPTION
            'Fulfillment order % cannot reserve inventory because its current status is %',
            v_order.fulfillment_order_id,
            v_order.status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock the fulfillment line.
     */
    SELECT *
    INTO v_item
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id =
          p_fulfillment_order_item_id
      AND fulfillment_order_id =
          v_order.fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % no longer exists on fulfillment order %',
            p_fulfillment_order_item_id,
            v_order.fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Calculate the quantity that has not yet been reserved,
     * shipped, or cancelled.
     */
    v_remaining_quantity :=
        v_item.requested_quantity
        - v_item.reserved_quantity
        - v_item.shipped_quantity
        - v_item.cancelled_quantity;

    IF v_remaining_quantity <= 0 THEN
        RAISE EXCEPTION
            'Fulfillment-order item % has no remaining quantity available to reserve',
            p_fulfillment_order_item_id
            USING ERRCODE = 'P0001';
    END IF;

    IF p_quantity > v_remaining_quantity THEN
        RAISE EXCEPTION
            'Reservation exceeds fulfillment-order item %. Requested: %, remaining reservable: %',
            p_fulfillment_order_item_id,
            p_quantity,
            v_remaining_quantity
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Resolve the inventory record using the fulfillment order's
     * warehouse and the fulfillment line's authoritative variant.
     *
     * UNIQUE (warehouse_id, variant_id) guarantees one matching row.
     */
    SELECT warehouse_inventory_id
    INTO v_warehouse_inventory_id
    FROM public.warehouse_inventory
    WHERE warehouse_id = v_order.warehouse_id
      AND variant_id = v_item.variant_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No warehouse inventory record exists for warehouse % and variant %',
            v_order.warehouse_id,
            v_item.variant_id
            USING ERRCODE = 'P0002';
    END IF;

    v_previous_status_code := v_order.status_code;

    /*
     * Delegate the inventory mutation to the inventory engine.
     */
    v_reservation :=
        inventory.create_reservation(
            p_warehouse_inventory_id => v_warehouse_inventory_id,
            p_quantity               => p_quantity,
            p_source_type_code       => 'fulfillment_order',
            p_source_id              => v_order.fulfillment_order_id,
            p_source_line_id         => v_item.fulfillment_order_item_id,
            p_expires_at             => p_expires_at,
            p_created_by_user_id     => p_performed_by_user_id,
            p_reason                 => p_reason,
            p_metadata               =>
                COALESCE(p_metadata, '{}'::jsonb)
                ||
                jsonb_build_object(
                    'fulfillment_order_id',
                    v_order.fulfillment_order_id,
                    'fulfillment_order_item_id',
                    v_item.fulfillment_order_item_id
                )
        );

    /*
     * Reflect the successful reservation on the fulfillment line.
     */
    UPDATE fulfillment.fulfillment_order_items
    SET
        reserved_quantity =
            reserved_quantity + p_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_item_id =
          v_item.fulfillment_order_item_id;

    /*
     * Recalculate the fulfillment order's reservation status.
     */
    SELECT
        COALESCE(SUM(requested_quantity), 0),
        COALESCE(SUM(reserved_quantity), 0),
        COALESCE(SUM(shipped_quantity), 0),
        COALESCE(SUM(cancelled_quantity), 0)
    INTO
        v_total_requested,
        v_total_reserved,
        v_total_shipped,
        v_total_cancelled
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id;

    IF v_total_reserved =
       v_total_requested
       - v_total_shipped
       - v_total_cancelled THEN

        v_new_status_code := 'reserved';

    ELSIF v_total_reserved > 0 THEN

        v_new_status_code := 'partially_reserved';

    ELSE

        v_new_status_code := 'pending';

    END IF;

    UPDATE fulfillment.fulfillment_orders
    SET
        status_code = v_new_status_code,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id;

    /*
     * Append the immutable fulfillment audit event.
     */
    INSERT INTO fulfillment.fulfillment_events (
        organization_id,
        fulfillment_order_id,
        fulfillment_order_item_id,
        reservation_id,
        event_type,
        previous_status_code,
        new_status_code,
        previous_quantity,
        new_quantity,
        reason,
        metadata,
        performed_by_user_id
    )
    VALUES (
        v_order.organization_id,
        v_order.fulfillment_order_id,
        v_item.fulfillment_order_item_id,
        v_reservation.reservation_id,
        'reserved',
        v_previous_status_code,
        v_new_status_code,
        v_item.reserved_quantity,
        v_item.reserved_quantity + p_quantity,
        p_reason,
        COALESCE(p_metadata, '{}'::jsonb)
        ||
        jsonb_build_object(
            'warehouse_inventory_id',
            v_warehouse_inventory_id,
            'reservation_quantity',
            p_quantity
        ),
        p_performed_by_user_id
    );

    RETURN v_reservation;
END;
$function$;

---------------------------------------------------------
----------------fulfillment.pick_fulfillment_order_item
---------------------------------------------------------

CREATE OR REPLACE FUNCTION fulfillment.pick_fulfillment_order_item(
    p_fulfillment_order_item_id bigint,
    p_quantity integer,
    p_performed_by_user_id integer DEFAULT NULL,
    p_reason text DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS fulfillment.fulfillment_order_items
LANGUAGE plpgsql
AS $function$
DECLARE
    v_fulfillment_order_id bigint;

    v_order fulfillment.fulfillment_orders%ROWTYPE;
    v_item fulfillment.fulfillment_order_items%ROWTYPE;
    v_updated_item fulfillment.fulfillment_order_items%ROWTYPE;

    v_remaining_pickable integer;

    v_previous_status_code varchar(30);
    v_new_status_code varchar(30);

    v_total_required bigint;
    v_total_reserved bigint;
    v_total_picked bigint;
    v_total_shipped bigint;
BEGIN
    /*
     * Validate parameters.
     */
    IF p_fulfillment_order_item_id IS NULL THEN
        RAISE EXCEPTION
            'fulfillment_order_item_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_fulfillment_order_item_id <= 0 THEN
        RAISE EXCEPTION
            'fulfillment_order_item_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION
            'Pick quantity must be greater than zero'
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
     * Resolve the parent fulfillment order.
     */
    SELECT fulfillment_order_id
    INTO v_fulfillment_order_id
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id =
          p_fulfillment_order_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % does not exist',
            p_fulfillment_order_item_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Lock the parent order first.
     */
    SELECT *
    INTO v_order
    FROM fulfillment.fulfillment_orders
    WHERE fulfillment_order_id =
          v_fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment order % does not exist',
            v_fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Only active warehouse-processing states may be picked.
     */
    IF v_order.status_code NOT IN (
        'partially_reserved',
        'reserved',
        'picking',
        'partially_picked'
    ) THEN
        RAISE EXCEPTION
            'Fulfillment order % cannot be picked because its current status is %',
            v_order.fulfillment_order_id,
            v_order.status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock the fulfillment line.
     */
    SELECT *
    INTO v_item
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id =
          p_fulfillment_order_item_id
      AND fulfillment_order_id =
          v_order.fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % no longer exists on fulfillment order %',
            p_fulfillment_order_item_id,
            v_order.fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Determine how much currently reserved inventory remains
     * available to pick.
     *
     * Shipped quantities are added back because shipping will move
     * inventory out of reserved_quantity while picked_quantity remains
     * a cumulative workflow quantity.
     */
    v_remaining_pickable :=
        v_item.reserved_quantity
        + v_item.shipped_quantity
        - v_item.picked_quantity;

    IF v_remaining_pickable <= 0 THEN
        RAISE EXCEPTION
            'Fulfillment-order item % has no reserved quantity remaining to pick',
            p_fulfillment_order_item_id
            USING ERRCODE = 'P0001';
    END IF;

    IF p_quantity > v_remaining_pickable THEN
        RAISE EXCEPTION
            'Pick quantity exceeds reserved availability for fulfillment-order item %. Requested pick: %, remaining pickable: %',
            p_fulfillment_order_item_id,
            p_quantity,
            v_remaining_pickable
            USING ERRCODE = 'P0001';
    END IF;

    v_previous_status_code := v_order.status_code;

    /*
     * Record the picked quantity on the fulfillment line.
     */
    UPDATE fulfillment.fulfillment_order_items
    SET
        picked_quantity =
            picked_quantity + p_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_item_id =
          v_item.fulfillment_order_item_id
    RETURNING *
    INTO v_updated_item;

    /*
     * Recalculate fulfillment-order progress.
     */
    SELECT
        COALESCE(
            SUM(requested_quantity - cancelled_quantity),
            0
        ),
        COALESCE(SUM(reserved_quantity), 0),
        COALESCE(SUM(picked_quantity), 0),
        COALESCE(SUM(shipped_quantity), 0)
    INTO
        v_total_required,
        v_total_reserved,
        v_total_picked,
        v_total_shipped
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id;

    IF v_total_picked >= v_total_required THEN
        v_new_status_code := 'picked';

    ELSIF v_total_picked > 0 THEN
        v_new_status_code := 'partially_picked';

    ELSIF v_total_reserved + v_total_shipped >=
          v_total_required THEN
        v_new_status_code := 'reserved';

    ELSIF v_total_reserved > 0 THEN
        v_new_status_code := 'partially_reserved';

    ELSE
        v_new_status_code := 'pending';
    END IF;

    UPDATE fulfillment.fulfillment_orders
    SET
        status_code = v_new_status_code,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id;

    /*
     * Append the immutable picking event.
     */
    INSERT INTO fulfillment.fulfillment_events (
        organization_id,
        fulfillment_order_id,
        fulfillment_order_item_id,
        event_type,
        previous_status_code,
        new_status_code,
        previous_quantity,
        new_quantity,
        reason,
        metadata,
        performed_by_user_id
    )
    VALUES (
        v_order.organization_id,
        v_order.fulfillment_order_id,
        v_item.fulfillment_order_item_id,
        'picked',
        v_previous_status_code,
        v_new_status_code,
        v_item.picked_quantity,
        v_updated_item.picked_quantity,
        p_reason,
        COALESCE(p_metadata, '{}'::jsonb)
        ||
        jsonb_build_object(
            'picked_quantity', p_quantity,
            'reserved_quantity',
                v_updated_item.reserved_quantity,
            'remaining_pickable',
                v_updated_item.reserved_quantity
                + v_updated_item.shipped_quantity
                - v_updated_item.picked_quantity
        ),
        p_performed_by_user_id
    );

    RETURN v_updated_item;
END;
$function$;

--------------------------------------------------------
----------pack fulfillment order item fucntion 
--------------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.pack_fulfillment_order_item(
    p_fulfillment_order_item_id bigint,
    p_quantity integer,
    p_performed_by_user_id integer DEFAULT NULL,
    p_reason text DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS fulfillment.fulfillment_order_items
LANGUAGE plpgsql
AS $function$
DECLARE
    v_fulfillment_order_id bigint;

    v_order fulfillment.fulfillment_orders%ROWTYPE;
    v_item fulfillment.fulfillment_order_items%ROWTYPE;
    v_updated_item fulfillment.fulfillment_order_items%ROWTYPE;

    v_remaining_packable integer;

    v_previous_status_code varchar(30);
    v_new_status_code varchar(30);

    v_total_required bigint;
    v_total_reserved bigint;
    v_total_picked bigint;
    v_total_packed bigint;
    v_total_shipped bigint;
BEGIN
    /*
     * Validate parameters.
     */
    IF p_fulfillment_order_item_id IS NULL THEN
        RAISE EXCEPTION
            'fulfillment_order_item_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_fulfillment_order_item_id <= 0 THEN
        RAISE EXCEPTION
            'fulfillment_order_item_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION
            'Pack quantity must be greater than zero'
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
     * Resolve the parent fulfillment order.
     */
    SELECT fulfillment_order_id
    INTO v_fulfillment_order_id
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id =
          p_fulfillment_order_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % does not exist',
            p_fulfillment_order_item_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Lock the parent order first.
     */
    SELECT *
    INTO v_order
    FROM fulfillment.fulfillment_orders
    WHERE fulfillment_order_id =
          v_fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment order % does not exist',
            v_fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Packing may begin after at least some inventory has been picked.
     * This supports packing while additional items are still being picked.
     */
    IF v_order.status_code NOT IN (
        'partially_picked',
        'picked',
        'packing',
        'partially_packed'
    ) THEN
        RAISE EXCEPTION
            'Fulfillment order % cannot be packed because its current status is %',
            v_order.fulfillment_order_id,
            v_order.status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock the fulfillment line.
     */
    SELECT *
    INTO v_item
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id =
          p_fulfillment_order_item_id
      AND fulfillment_order_id =
          v_order.fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % no longer exists on fulfillment order %',
            p_fulfillment_order_item_id,
            v_order.fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Only picked inventory may be packed.
     */
    v_remaining_packable :=
        v_item.picked_quantity
        - v_item.packed_quantity;

    IF v_remaining_packable <= 0 THEN
        RAISE EXCEPTION
            'Fulfillment-order item % has no picked quantity remaining to pack',
            p_fulfillment_order_item_id
            USING ERRCODE = 'P0001';
    END IF;

    IF p_quantity > v_remaining_packable THEN
        RAISE EXCEPTION
            'Pack quantity exceeds picked availability for fulfillment-order item %. Requested pack: %, remaining packable: %',
            p_fulfillment_order_item_id,
            p_quantity,
            v_remaining_packable
            USING ERRCODE = 'P0001';
    END IF;

    v_previous_status_code := v_order.status_code;

    /*
     * Record the packed quantity on the fulfillment line.
     */
    UPDATE fulfillment.fulfillment_order_items
    SET
        packed_quantity =
            packed_quantity + p_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_item_id =
          v_item.fulfillment_order_item_id
    RETURNING *
    INTO v_updated_item;

    /*
     * Recalculate the fulfillment order's workflow status.
     *
     * Later workflow stages take precedence over earlier stages.
     */
    SELECT
        COALESCE(
            SUM(requested_quantity - cancelled_quantity),
            0
        ),
        COALESCE(SUM(reserved_quantity), 0),
        COALESCE(SUM(picked_quantity), 0),
        COALESCE(SUM(packed_quantity), 0),
        COALESCE(SUM(shipped_quantity), 0)
    INTO
        v_total_required,
        v_total_reserved,
        v_total_picked,
        v_total_packed,
        v_total_shipped
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id;

    IF v_total_packed >= v_total_required THEN
        v_new_status_code := 'packed';

    ELSIF v_total_packed > 0 THEN
        v_new_status_code := 'partially_packed';

    ELSIF v_total_picked >= v_total_required THEN
        v_new_status_code := 'picked';

    ELSIF v_total_picked > 0 THEN
        v_new_status_code := 'partially_picked';

    ELSIF v_total_reserved + v_total_shipped >=
          v_total_required THEN
        v_new_status_code := 'reserved';

    ELSIF v_total_reserved > 0 THEN
        v_new_status_code := 'partially_reserved';

    ELSE
        v_new_status_code := 'pending';
    END IF;

    UPDATE fulfillment.fulfillment_orders
    SET
        status_code = v_new_status_code,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id;

    /*
     * Append the immutable packing event.
     */
    INSERT INTO fulfillment.fulfillment_events (
        organization_id,
        fulfillment_order_id,
        fulfillment_order_item_id,
        event_type,
        previous_status_code,
        new_status_code,
        previous_quantity,
        new_quantity,
        reason,
        metadata,
        performed_by_user_id
    )
    VALUES (
        v_order.organization_id,
        v_order.fulfillment_order_id,
        v_item.fulfillment_order_item_id,
        'packed',
        v_previous_status_code,
        v_new_status_code,
        v_item.packed_quantity,
        v_updated_item.packed_quantity,
        p_reason,
        COALESCE(p_metadata, '{}'::jsonb)
        ||
        jsonb_build_object(
            'packed_quantity',
                p_quantity,
            'picked_quantity',
                v_updated_item.picked_quantity,
            'remaining_packable',
                v_updated_item.picked_quantity
                - v_updated_item.packed_quantity
        ),
        p_performed_by_user_id
    );

    RETURN v_updated_item;
END;
$function$;
-------------------------------------------
----------------shipping function
-------------------------------------------

CREATE OR REPLACE FUNCTION fulfillment.ship_fulfillment_order_item(
    p_reservation_id bigint,
    p_performed_by_user_id integer DEFAULT NULL,
    p_reason text DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS fulfillment.fulfillment_order_items
LANGUAGE plpgsql
AS $function$
DECLARE
    v_reservation inventory.reservations%ROWTYPE;
    v_fulfilled_reservation inventory.reservations%ROWTYPE;

    v_order fulfillment.fulfillment_orders%ROWTYPE;
    v_item fulfillment.fulfillment_order_items%ROWTYPE;
    v_updated_item fulfillment.fulfillment_order_items%ROWTYPE;

    v_sales_order_item public.sales_order_items%ROWTYPE;

    v_previous_status_code varchar(30);
    v_new_status_code varchar(30);

    v_remaining_shippable integer;

    v_total_required bigint;
    v_total_reserved bigint;
    v_total_picked bigint;
    v_total_packed bigint;
    v_total_shipped bigint;
BEGIN
    /*
     * Validate parameters.
     */
    IF p_reservation_id IS NULL THEN
        RAISE EXCEPTION
            'reservation_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_reservation_id <= 0 THEN
        RAISE EXCEPTION
            'reservation_id must be greater than zero'
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
     * Lock and validate the inventory reservation.
     */
    SELECT *
    INTO v_reservation
    FROM inventory.reservations
    WHERE reservation_id = p_reservation_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Reservation % does not exist',
            p_reservation_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_reservation.status_code <> 'active' THEN
        RAISE EXCEPTION
            'Reservation % cannot be shipped because its current status is %',
            p_reservation_id,
            v_reservation.status_code
            USING ERRCODE = 'P0001';
    END IF;

    IF v_reservation.source_type_code <> 'fulfillment_order' THEN
        RAISE EXCEPTION
            'Reservation % is not associated with a fulfillment order',
            p_reservation_id
            USING ERRCODE = 'P0001';
    END IF;

    IF v_reservation.source_id IS NULL
       OR v_reservation.source_line_id IS NULL THEN
        RAISE EXCEPTION
            'Reservation % is missing its fulfillment source identifiers',
            p_reservation_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock the fulfillment order.
     */
    SELECT *
    INTO v_order
    FROM fulfillment.fulfillment_orders
    WHERE fulfillment_order_id =
          v_reservation.source_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment order % associated with reservation % does not exist',
            v_reservation.source_id,
            p_reservation_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Shipping may occur only after inventory has been packed.
     */
    IF v_order.status_code NOT IN (
        'partially_packed',
        'packed',
        'partially_shipped'
    ) THEN
        RAISE EXCEPTION
            'Fulfillment order % cannot be shipped because its current status is %',
            v_order.fulfillment_order_id,
            v_order.status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock the fulfillment line identified by the reservation.
     */
    SELECT *
    INTO v_item
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id =
          v_reservation.source_line_id
      AND fulfillment_order_id =
          v_order.fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % associated with reservation % does not exist on fulfillment order %',
            v_reservation.source_line_id,
            p_reservation_id,
            v_order.fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Confirm that the reservation points to the same warehouse
     * inventory represented by this fulfillment order and line.
     */
    IF NOT EXISTS (
        SELECT 1
        FROM public.warehouse_inventory wi
        WHERE wi.warehouse_inventory_id =
              v_reservation.warehouse_inventory_id
          AND wi.warehouse_id =
              v_order.warehouse_id
          AND wi.variant_id =
              v_item.variant_id
    ) THEN
        RAISE EXCEPTION
            'Reservation % does not match warehouse % and variant % for fulfillment-order item %',
            p_reservation_id,
            v_order.warehouse_id,
            v_item.variant_id,
            v_item.fulfillment_order_item_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Only packed inventory may ship.
     */
    v_remaining_shippable :=
        v_item.packed_quantity
        - v_item.shipped_quantity;

    IF v_remaining_shippable <= 0 THEN
        RAISE EXCEPTION
            'Fulfillment-order item % has no packed quantity remaining to ship',
            v_item.fulfillment_order_item_id
            USING ERRCODE = 'P0001';
    END IF;

    IF v_reservation.quantity > v_remaining_shippable THEN
        RAISE EXCEPTION
            'Reservation % quantity exceeds packed availability for fulfillment-order item %. Reservation quantity: %, remaining shippable: %',
            p_reservation_id,
            v_item.fulfillment_order_item_id,
            v_reservation.quantity,
            v_remaining_shippable
            USING ERRCODE = 'P0001';
    END IF;

    IF v_reservation.quantity > v_item.reserved_quantity THEN
        RAISE EXCEPTION
            'Reservation % quantity exceeds the fulfillment line reserved balance. Reservation quantity: %, line reserved quantity: %',
            p_reservation_id,
            v_reservation.quantity,
            v_item.reserved_quantity
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock and validate the related sales-order item.
     */
    SELECT *
    INTO v_sales_order_item
    FROM public.sales_order_items
    WHERE sales_order_item_id =
          v_item.sales_order_item_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Sales-order item % associated with fulfillment-order item % does not exist',
            v_item.sales_order_item_id,
            v_item.fulfillment_order_item_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_sales_order_item.fulfilled_quantity
       + v_sales_order_item.cancelled_quantity
       + v_reservation.quantity
       > v_sales_order_item.quantity THEN
        RAISE EXCEPTION
            'Shipping reservation % would exceed sales-order item %. Ordered: %, fulfilled: %, cancelled: %, shipping now: %',
            p_reservation_id,
            v_sales_order_item.sales_order_item_id,
            v_sales_order_item.quantity,
            v_sales_order_item.fulfilled_quantity,
            v_sales_order_item.cancelled_quantity,
            v_reservation.quantity
            USING ERRCODE = 'P0001';
    END IF;

    v_previous_status_code := v_order.status_code;

    /*
     * Delegate inventory consumption to the inventory engine.
     *
     * This decreases both quantity_on_hand and quantity_reserved
     * and moves the reservation to fulfilled.
     */
    v_fulfilled_reservation :=
        inventory.fulfill_reservation(
            p_reservation_id        => p_reservation_id,
            p_performed_by_user_id  => p_performed_by_user_id,
            p_reason                => p_reason,
            p_metadata              =>
                COALESCE(p_metadata, '{}'::jsonb)
                ||
                jsonb_build_object(
                    'fulfillment_order_id',
                    v_order.fulfillment_order_id,
                    'fulfillment_order_item_id',
                    v_item.fulfillment_order_item_id
                )
        );

    /*
     * Move the quantity from reserved to shipped on the
     * fulfillment line.
     */
    UPDATE fulfillment.fulfillment_order_items
    SET
        reserved_quantity =
            reserved_quantity - v_reservation.quantity,
        shipped_quantity =
            shipped_quantity + v_reservation.quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_item_id =
          v_item.fulfillment_order_item_id
    RETURNING *
    INTO v_updated_item;

/*
 * Record fulfillment against the sales-order line.
 */
 
UPDATE public.sales_order_items
SET
    fulfilled_quantity =
        fulfilled_quantity + v_reservation.quantity
WHERE sales_order_item_id =
      v_item.sales_order_item_id
RETURNING *
INTO v_sales_order_item;

/*
 * Keep the parent sales-order status synchronized.
 */
PERFORM public.recalculate_sales_order_status(
    v_order.sales_order_id
);

    /*
     * Recalculate fulfillment-order progress.
     * Later workflow stages take precedence.
     */
    SELECT
        COALESCE(
            SUM(requested_quantity - cancelled_quantity),
            0
        ),
        COALESCE(SUM(reserved_quantity), 0),
        COALESCE(SUM(picked_quantity), 0),
        COALESCE(SUM(packed_quantity), 0),
        COALESCE(SUM(shipped_quantity), 0)
    INTO
        v_total_required,
        v_total_reserved,
        v_total_picked,
        v_total_packed,
        v_total_shipped
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id;

    IF v_total_shipped >= v_total_required THEN
        v_new_status_code := 'shipped';

    ELSIF v_total_shipped > 0 THEN
        v_new_status_code := 'partially_shipped';

    ELSIF v_total_packed >= v_total_required THEN
        v_new_status_code := 'packed';

    ELSIF v_total_packed > 0 THEN
        v_new_status_code := 'partially_packed';

    ELSIF v_total_picked >= v_total_required THEN
        v_new_status_code := 'picked';

    ELSIF v_total_picked > 0 THEN
        v_new_status_code := 'partially_picked';

    ELSIF v_total_reserved >= v_total_required THEN
        v_new_status_code := 'reserved';

    ELSIF v_total_reserved > 0 THEN
        v_new_status_code := 'partially_reserved';

    ELSE
        v_new_status_code := 'pending';
    END IF;

  UPDATE fulfillment.fulfillment_orders
SET
    status_code = v_new_status_code,

    completed_at =
        CASE
            WHEN v_new_status_code = 'shipped'
                THEN CURRENT_TIMESTAMP
            ELSE NULL
        END,

    cancelled_at = NULL,

    updated_at = CURRENT_TIMESTAMP
	WHERE fulfillment_order_id =
      v_order.fulfillment_order_id
	  RETURNING *
	  INTO v_order;

    /*
     * Append the immutable shipping event.
     */
    INSERT INTO fulfillment.fulfillment_events (
        organization_id,
        fulfillment_order_id,
        fulfillment_order_item_id,
        reservation_id,
        event_type,
        previous_status_code,
        new_status_code,
        previous_quantity,
        new_quantity,
        reason,
        metadata,
        performed_by_user_id
    )
    VALUES (
        v_order.organization_id,
        v_order.fulfillment_order_id,
        v_item.fulfillment_order_item_id,
        v_fulfilled_reservation.reservation_id,
        'shipped',
        v_previous_status_code,
        v_new_status_code,
        v_item.shipped_quantity,
        v_updated_item.shipped_quantity,
        p_reason,
        COALESCE(p_metadata, '{}'::jsonb)
        ||
        jsonb_build_object(
            'shipped_quantity',
                v_reservation.quantity,
            'warehouse_inventory_id',
                v_reservation.warehouse_inventory_id,
            'reservation_status',
                v_fulfilled_reservation.status_code,
            'remaining_reserved_quantity',
                v_updated_item.reserved_quantity
        ),
        p_performed_by_user_id
    );

    RETURN v_updated_item;
END;
$function$;
--------------------------------------------------
-----------public.recalculate_sales_order_status
--------------------------------------------------
CREATE OR REPLACE FUNCTION public.recalculate_sales_order_status(
    p_sales_order_id integer
)
RETURNS public.sales_orders
LANGUAGE plpgsql
AS $function$
DECLARE
    v_sales_order public.sales_orders%ROWTYPE;
    v_updated_sales_order public.sales_orders%ROWTYPE;

    v_total_quantity bigint;
    v_total_fulfilled bigint;
    v_total_cancelled bigint;
    v_total_required bigint;

    v_new_status varchar(30);
BEGIN
    /*
     * Validate the request.
     */
    IF p_sales_order_id IS NULL THEN
        RAISE EXCEPTION
            'sales_order_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_sales_order_id <= 0 THEN
        RAISE EXCEPTION
            'sales_order_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    /*
     * Lock the parent sales order.
     */
    SELECT *
    INTO v_sales_order
    FROM public.sales_orders
    WHERE sales_order_id = p_sales_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Sales order % does not exist',
            p_sales_order_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Do not recalculate an explicitly cancelled order.
     */
    IF v_sales_order.status = 'CANCELLED' THEN
        RETURN v_sales_order;
    END IF;

    /*
     * Calculate fulfillment progress across all sales-order items.
     */
    SELECT
        COALESCE(SUM(quantity), 0),
        COALESCE(SUM(fulfilled_quantity), 0),
        COALESCE(SUM(cancelled_quantity), 0)
    INTO
        v_total_quantity,
        v_total_fulfilled,
        v_total_cancelled
    FROM public.sales_order_items
    WHERE sales_order_id = p_sales_order_id;

    IF v_total_quantity = 0 THEN
        RAISE EXCEPTION
            'Sales order % has no sales-order items',
            p_sales_order_id
            USING ERRCODE = 'P0001';
    END IF;

    v_total_required :=
        v_total_quantity - v_total_cancelled;

    /*
     * Preserve the current status when nothing has shipped.
     */
    IF v_total_fulfilled = 0 THEN
        RETURN v_sales_order;
    END IF;

    IF v_total_required > 0
       AND v_total_fulfilled >= v_total_required THEN
        v_new_status := 'FULFILLED';
    ELSE
        v_new_status := 'PARTIALLY_FULFILLED';
    END IF;

    UPDATE public.sales_orders
    SET
        status = v_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE sales_order_id = p_sales_order_id
    RETURNING *
    INTO v_updated_sales_order;

    RETURN v_updated_sales_order;
END;
$function$;
--------------------------------------------------------------
------------ fullfilment.cancel_fullfilment_order_items
--------------------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.cancel_fulfillment_order_item(
    p_reservation_id bigint,
    p_performed_by_user_id integer DEFAULT NULL,
    p_reason text DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS fulfillment.fulfillment_order_items
LANGUAGE plpgsql
AS $function$
DECLARE
    v_reservation inventory.reservations%ROWTYPE;
    v_cancelled_reservation inventory.reservations%ROWTYPE;

    v_order fulfillment.fulfillment_orders%ROWTYPE;
    v_item fulfillment.fulfillment_order_items%ROWTYPE;
    v_updated_item fulfillment.fulfillment_order_items%ROWTYPE;

    v_previous_status_code varchar(30);
    v_new_status_code varchar(30);
BEGIN
    /*
     * Validate parameters.
     */
    IF p_reservation_id IS NULL THEN
        RAISE EXCEPTION
            'reservation_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_reservation_id <= 0 THEN
        RAISE EXCEPTION
            'reservation_id must be greater than zero'
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
     * Lock the reservation.
     */
    SELECT *
    INTO v_reservation
    FROM inventory.reservations
    WHERE reservation_id = p_reservation_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Reservation % does not exist',
            p_reservation_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_reservation.status_code <> 'active' THEN
        RAISE EXCEPTION
            'Reservation % cannot be cancelled from fulfillment because its current status is %',
            p_reservation_id,
            v_reservation.status_code
            USING ERRCODE = 'P0001';
    END IF;

    IF v_reservation.source_type_code <> 'fulfillment_order' THEN
        RAISE EXCEPTION
            'Reservation % is not associated with a fulfillment order',
            p_reservation_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock the parent fulfillment order.
     */
    SELECT *
    INTO v_order
    FROM fulfillment.fulfillment_orders
    WHERE fulfillment_order_id = v_reservation.source_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment order % does not exist',
            v_reservation.source_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * For this first cancellation implementation, only quantities that
     * have not progressed into picking may be cancelled.
     */
    IF v_order.status_code NOT IN (
        'pending',
        'partially_reserved',
        'reserved'
    ) THEN
        RAISE EXCEPTION
            'Fulfillment order % cannot be cancelled at its current status %',
            v_order.fulfillment_order_id,
            v_order.status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock the fulfillment item.
     */
    SELECT *
    INTO v_item
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id = v_reservation.source_line_id
      AND fulfillment_order_id = v_order.fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % does not exist on fulfillment order %',
            v_reservation.source_line_id,
            v_order.fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_item.picked_quantity > 0
       OR v_item.packed_quantity > 0
       OR v_item.shipped_quantity > 0 THEN
        RAISE EXCEPTION
            'Fulfillment-order item % cannot be cancelled because warehouse processing has already begun',
            v_item.fulfillment_order_item_id
            USING ERRCODE = 'P0001';
    END IF;

    IF v_reservation.quantity > v_item.reserved_quantity THEN
        RAISE EXCEPTION
            'Reservation % quantity exceeds fulfillment item reserved quantity',
            p_reservation_id
            USING ERRCODE = 'P0001';
    END IF;

    v_previous_status_code := v_order.status_code;

    /*
     * Delegate inventory cancellation to the inventory engine.
     */
    v_cancelled_reservation :=
        inventory.cancel_reservation(
            p_reservation_id       => p_reservation_id,
            p_performed_by_user_id => p_performed_by_user_id,
            p_reason               => p_reason,
            p_metadata             =>
                COALESCE(p_metadata, '{}'::jsonb)
                ||
                jsonb_build_object(
                    'fulfillment_order_id',
                    v_order.fulfillment_order_id,
                    'fulfillment_order_item_id',
                    v_item.fulfillment_order_item_id
                )
        );

    /*
     * Move the quantity out of reserved and into cancelled.
     */
    UPDATE fulfillment.fulfillment_order_items
    SET
        reserved_quantity =
            reserved_quantity - v_reservation.quantity,
        cancelled_quantity =
            cancelled_quantity + v_reservation.quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_item_id =
          v_item.fulfillment_order_item_id
    RETURNING *
    INTO v_updated_item;

    /*
     * Recalculate the parent fulfillment-order status.
     */
    IF NOT EXISTS (
        SELECT 1
        FROM fulfillment.fulfillment_order_items
        WHERE fulfillment_order_id = v_order.fulfillment_order_id
          AND cancelled_quantity < requested_quantity
    ) THEN
        v_new_status_code := 'cancelled';
    ELSE
        v_new_status_code := 'partially_reserved';
    END IF;

    UPDATE fulfillment.fulfillment_orders
    SET
        status_code = v_new_status_code,
        cancelled_at =
            CASE
                WHEN v_new_status_code = 'cancelled'
                    THEN CURRENT_TIMESTAMP
                ELSE NULL
            END,
        completed_at = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id
    RETURNING *
    INTO v_order;

    /*
     * Append immutable fulfillment cancellation event.
     */
    INSERT INTO fulfillment.fulfillment_events (
        organization_id,
        fulfillment_order_id,
        fulfillment_order_item_id,
        reservation_id,
        event_type,
        previous_status_code,
        new_status_code,
        previous_quantity,
        new_quantity,
        reason,
        metadata,
        performed_by_user_id
    )
    VALUES (
        v_order.organization_id,
        v_order.fulfillment_order_id,
        v_item.fulfillment_order_item_id,
        v_cancelled_reservation.reservation_id,
        'cancelled',
        v_previous_status_code,
        v_new_status_code,
        v_item.cancelled_quantity,
        v_updated_item.cancelled_quantity,
        p_reason,
        COALESCE(p_metadata, '{}'::jsonb)
        ||
        jsonb_build_object(
            'cancelled_quantity',
                v_reservation.quantity,
            'remaining_reserved_quantity',
                v_updated_item.reserved_quantity,
            'reservation_status',
                v_cancelled_reservation.status_code
        ),
        p_performed_by_user_id
    );

    RETURN v_updated_item;
END;
$function$;
------------------------------------------------------------------------------
------------------------fullfillment.partial_cancel_fulfillment_order_item()
------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fulfillment.partial_cancel_fulfillment_order_item(
    p_reservation_id bigint,
    p_quantity integer,
    p_performed_by_user_id integer DEFAULT NULL,
    p_reason text DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS fulfillment.fulfillment_order_items
LANGUAGE plpgsql
AS $function$
DECLARE
    v_reservation inventory.reservations%ROWTYPE;
    v_adjusted_reservation inventory.reservations%ROWTYPE;

    v_order fulfillment.fulfillment_orders%ROWTYPE;
    v_item fulfillment.fulfillment_order_items%ROWTYPE;
    v_updated_item fulfillment.fulfillment_order_items%ROWTYPE;

    v_previous_status_code varchar(30);
    v_new_status_code varchar(30);

    v_new_reservation_quantity integer;

    v_total_required bigint;
    v_total_reserved bigint;
    v_total_picked bigint;
    v_total_packed bigint;
    v_total_shipped bigint;
BEGIN
    /*
     * Validate parameters.
     */
    IF p_reservation_id IS NULL THEN
        RAISE EXCEPTION
            'reservation_id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_reservation_id <= 0 THEN
        RAISE EXCEPTION
            'reservation_id must be greater than zero'
            USING ERRCODE = '22023';
    END IF;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION
            'Partial cancellation quantity must be greater than zero'
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
     * Lock reservation.
     */
    SELECT *
    INTO v_reservation
    FROM inventory.reservations
    WHERE reservation_id = p_reservation_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Reservation % does not exist',
            p_reservation_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_reservation.status_code <> 'active' THEN
        RAISE EXCEPTION
            'Reservation % cannot be partially cancelled because its current status is %',
            p_reservation_id,
            v_reservation.status_code
            USING ERRCODE = 'P0001';
    END IF;

    IF v_reservation.source_type_code <> 'fulfillment_order' THEN
        RAISE EXCEPTION
            'Reservation % is not associated with a fulfillment order',
            p_reservation_id
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * This function is intentionally for PARTIAL cancellation only.
     * Full reservation cancellation remains the responsibility of
     * cancel_fulfillment_order_item().
     */
    IF p_quantity >= v_reservation.quantity THEN
        RAISE EXCEPTION
            'Partial cancellation quantity must be less than reservation %. Reservation quantity: %, requested cancellation: %',
            p_reservation_id,
            v_reservation.quantity,
            p_quantity
            USING ERRCODE = '22023';
    END IF;

    /*
     * Lock parent fulfillment order.
     */
    SELECT *
    INTO v_order
    FROM fulfillment.fulfillment_orders
    WHERE fulfillment_order_id = v_reservation.source_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment order % does not exist',
            v_reservation.source_id
            USING ERRCODE = 'P0002';
    END IF;

    /*
     * Partial cancellation is allowed only before picking begins.
     */
    IF v_order.status_code NOT IN (
        'partially_reserved',
        'reserved'
    ) THEN
        RAISE EXCEPTION
            'Fulfillment order % cannot be partially cancelled at its current status %',
            v_order.fulfillment_order_id,
            v_order.status_code
            USING ERRCODE = 'P0001';
    END IF;

    /*
     * Lock fulfillment item.
     */
    SELECT *
    INTO v_item
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_item_id = v_reservation.source_line_id
      AND fulfillment_order_id = v_order.fulfillment_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Fulfillment-order item % does not exist on fulfillment order %',
            v_reservation.source_line_id,
            v_order.fulfillment_order_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_item.picked_quantity > 0
       OR v_item.packed_quantity > 0
       OR v_item.shipped_quantity > 0 THEN
        RAISE EXCEPTION
            'Fulfillment-order item % cannot be partially cancelled because warehouse processing has already begun',
            v_item.fulfillment_order_item_id
            USING ERRCODE = 'P0001';
    END IF;

    IF p_quantity > v_item.reserved_quantity THEN
        RAISE EXCEPTION
            'Partial cancellation quantity exceeds fulfillment item reserved quantity. Requested cancellation: %, reserved: %',
            p_quantity,
            v_item.reserved_quantity
            USING ERRCODE = 'P0001';
    END IF;

    v_previous_status_code := v_order.status_code;

    v_new_reservation_quantity :=
        v_reservation.quantity - p_quantity;

    /*
     * Delegate reservation-balance adjustment to inventory.
     *
     * Example:
     * reservation quantity 5
     * cancel quantity      2
     * new reservation      3
     */
    v_adjusted_reservation :=
        inventory.adjust_reservation(
            p_reservation_id       => p_reservation_id,
            p_new_quantity         => v_new_reservation_quantity,
            p_performed_by_user_id => p_performed_by_user_id,
            p_reason               => p_reason,
            p_metadata             =>
                COALESCE(p_metadata, '{}'::jsonb)
                ||
                jsonb_build_object(
                    'operation',
                    'partial_fulfillment_cancellation',
                    'cancelled_quantity',
                    p_quantity,
                    'fulfillment_order_id',
                    v_order.fulfillment_order_id,
                    'fulfillment_order_item_id',
                    v_item.fulfillment_order_item_id
                )
        );

    /*
     * Move cancelled quantity out of the fulfillment reserved balance.
     */
    UPDATE fulfillment.fulfillment_order_items
    SET
        reserved_quantity =
            reserved_quantity - p_quantity,
        cancelled_quantity =
            cancelled_quantity + p_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_item_id =
          v_item.fulfillment_order_item_id
    RETURNING *
    INTO v_updated_item;

    /*
     * Recalculate parent fulfillment state.
     *
     * required = requested - cancelled
     */
    SELECT
        COALESCE(
            SUM(requested_quantity - cancelled_quantity),
            0
        ),
        COALESCE(SUM(reserved_quantity), 0),
        COALESCE(SUM(picked_quantity), 0),
        COALESCE(SUM(packed_quantity), 0),
        COALESCE(SUM(shipped_quantity), 0)
    INTO
        v_total_required,
        v_total_reserved,
        v_total_picked,
        v_total_packed,
        v_total_shipped
    FROM fulfillment.fulfillment_order_items
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id;

    IF v_total_required = 0 THEN
        v_new_status_code := 'cancelled';

    ELSIF v_total_shipped >= v_total_required THEN
        v_new_status_code := 'shipped';

    ELSIF v_total_shipped > 0 THEN
        v_new_status_code := 'partially_shipped';

    ELSIF v_total_packed >= v_total_required THEN
        v_new_status_code := 'packed';

    ELSIF v_total_packed > 0 THEN
        v_new_status_code := 'partially_packed';

    ELSIF v_total_picked >= v_total_required THEN
        v_new_status_code := 'picked';

    ELSIF v_total_picked > 0 THEN
        v_new_status_code := 'partially_picked';

    ELSIF v_total_reserved >= v_total_required THEN
        v_new_status_code := 'reserved';

    ELSIF v_total_reserved > 0 THEN
        v_new_status_code := 'partially_reserved';

    ELSE
        v_new_status_code := 'pending';
    END IF;

    UPDATE fulfillment.fulfillment_orders
    SET
        status_code = v_new_status_code,
        cancelled_at =
            CASE
                WHEN v_new_status_code = 'cancelled'
                    THEN CURRENT_TIMESTAMP
                ELSE NULL
            END,
        completed_at =
            CASE
                WHEN v_new_status_code = 'shipped'
                    THEN CURRENT_TIMESTAMP
                ELSE NULL
            END,
        updated_at = CURRENT_TIMESTAMP
    WHERE fulfillment_order_id =
          v_order.fulfillment_order_id
    RETURNING *
    INTO v_order;

    /*
     * Append immutable fulfillment event.
     */
    INSERT INTO fulfillment.fulfillment_events (
        organization_id,
        fulfillment_order_id,
        fulfillment_order_item_id,
        reservation_id,
        event_type,
        previous_status_code,
        new_status_code,
        previous_quantity,
        new_quantity,
        reason,
        metadata,
        performed_by_user_id
    )
    VALUES (
        v_order.organization_id,
        v_order.fulfillment_order_id,
        v_item.fulfillment_order_item_id,
        v_adjusted_reservation.reservation_id,
        'partially_cancelled',
        v_previous_status_code,
        v_new_status_code,
        v_item.cancelled_quantity,
        v_updated_item.cancelled_quantity,
        p_reason,
        COALESCE(p_metadata, '{}'::jsonb)
        ||
        jsonb_build_object(
            'cancelled_quantity',
                p_quantity,
            'previous_reservation_quantity',
                v_reservation.quantity,
            'new_reservation_quantity',
                v_adjusted_reservation.quantity,
            'remaining_reserved_quantity',
                v_updated_item.reserved_quantity
        ),
        p_performed_by_user_id
    );

    RETURN v_updated_item;
END;
$function$;
---------------------------------------------------------------
---------
---------------------------------------------------------------
