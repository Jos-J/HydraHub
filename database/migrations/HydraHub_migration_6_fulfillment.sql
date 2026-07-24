-- migration 6 -- fulfillment 

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
----
----------------------------------------------
