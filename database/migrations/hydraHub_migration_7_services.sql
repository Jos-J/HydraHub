--------------------------------------------------------------------------------
------------------- creating table services.services
-------------------------------------------------------------------------------
CREATE TABLE services.services (
    service_id BIGSERIAL PRIMARY KEY,

    organization_id BIGINT NOT NULL,

    service_code VARCHAR(50) NOT NULL,
    service_name VARCHAR(150) NOT NULL,
    description TEXT,

    price NUMERIC(12, 2) NOT NULL,
    duration_minutes INTEGER NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 1,

    service_status_id BIGINT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_services_org_code
        UNIQUE (organization_id, service_code),

    CONSTRAINT chk_services_price
        CHECK (price >= 0),

    CONSTRAINT chk_services_duration
        CHECK (duration_minutes > 0),

    CONSTRAINT chk_services_capacity
        CHECK (capacity > 0),

    CONSTRAINT fk_services_status
        FOREIGN KEY (service_status_id)
        REFERENCES services.service_statuses(service_status_id)
);
-----------------------------------------------------------------
---------------------- creating services.employee_services table
---------------------------------------------------------------
CREATE TABLE services.employee_services (
    employee_service_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    service_id BIGINT NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_employee_services_organization
        FOREIGN KEY (organization_id)
        REFERENCES public.organizations(organization_id),

    CONSTRAINT fk_employee_services_user
        FOREIGN KEY (user_id)
        REFERENCES public.users(user_id),

    CONSTRAINT fk_employee_services_service
        FOREIGN KEY (service_id)
        REFERENCES services.services(service_id),

    CONSTRAINT uq_employee_services_assignment
        UNIQUE (organization_id, user_id, service_id)
);
----------------------------------------------------------------
---------------services.service_inventory_requirements
---------------------------------------------------------------
CREATE TABLE services.service_inventory_requirements (
    service_inventory_requirement_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    service_id BIGINT NOT NULL,

    product_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,

    quantity_required INTEGER NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_service_inventory_quantity
        CHECK (quantity_required > 0),

    CONSTRAINT uq_service_inventory_requirement
        UNIQUE (organization_id, service_id, variant_id),

    CONSTRAINT fk_service_inventory_org_service
        FOREIGN KEY (organization_id, service_id)
        REFERENCES services.services (
            organization_id,
            service_id
        ),

    CONSTRAINT fk_service_inventory_org_product
        FOREIGN KEY (organization_id, product_id)
        REFERENCES public.products (
            organization_id,
            product_id
        ),

    CONSTRAINT fk_service_inventory_product_variant
        FOREIGN KEY (product_id, variant_id)
        REFERENCES public.product_variants (
            product_id,
            variant_id
        )
);

--------------------------------------------------------
------------services.service_order_status
--------------------------------------------------------

CREATE TABLE services.service_order_statuses (
    service_order_status_id BIGSERIAL PRIMARY KEY,
    status_code VARCHAR(50) NOT NULL UNIQUE,
    status_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------------------------
------------services.service_orders
---------------------------------------------------------------------

CREATE TABLE services.service_orders (
    service_order_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    sales_order_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,

    service_order_status_id BIGINT NOT NULL,

    priority VARCHAR(20) NOT NULL DEFAULT 'normal',
    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_service_orders_priority
        CHECK (priority IN ('low', 'normal', 'high', 'urgent')),

    CONSTRAINT uq_service_orders_sales_order
        UNIQUE (organization_id, sales_order_id),

    CONSTRAINT fk_service_orders_org_sales_order
        FOREIGN KEY (organization_id, sales_order_id)
        REFERENCES public.sales_orders (
            organization_id,
            sales_order_id
        ),

    CONSTRAINT fk_service_orders_org_customer
        FOREIGN KEY (organization_id, customer_id)
        REFERENCES public.customers (
            organization_id,
            customer_id
        ),

    CONSTRAINT fk_service_orders_status
        FOREIGN KEY (service_order_status_id)
        REFERENCES services.service_order_statuses (
            service_order_status_id
        )
);

-------------------------------------------------------------------
-----------services.service_order_item_statuses
-------------------------------------------------------------------

CREATE TABLE services.service_order_item_statuses (
    service_order_item_status_id BIGSERIAL PRIMARY KEY,
    status_code VARCHAR(50) NOT NULL UNIQUE,
    status_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--------------------------------------------------------------------
----------------services.service_order_items
--------------------------------------------------------------------

CREATE TABLE services.service_order_items (
    service_order_item_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    service_order_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,

    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price NUMERIC(12, 2) NOT NULL,

    line_total NUMERIC(12, 2)
        GENERATED ALWAYS AS (quantity * unit_price) STORED,

    service_order_item_status_id BIGINT NOT NULL,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_service_order_items_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_service_order_items_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT fk_service_order_items_org_order
        FOREIGN KEY (organization_id, service_order_id)
        REFERENCES services.service_orders (
            organization_id,
            service_order_id
        ),

    CONSTRAINT fk_service_order_items_org_service
        FOREIGN KEY (organization_id, service_id)
        REFERENCES services.services (
            organization_id,
            service_id
        ),

    CONSTRAINT fk_service_order_items_status
        FOREIGN KEY (service_order_item_status_id)
        REFERENCES services.service_order_item_statuses (
            service_order_item_status_id
        )
);
--------------------------------------------------------------------
------------------service.employee_availability table
-------------------------------------------------------------------
CREATE TABLE services.employee_availability (
    employee_availability_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    day_of_week SMALLINT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_employee_availability_day
        CHECK (day_of_week BETWEEN 0 AND 6),

    CONSTRAINT chk_employee_availability_time
        CHECK (start_time < end_time),

    CONSTRAINT uq_employee_availability_window
        UNIQUE (
            organization_id,
            user_id,
            day_of_week,
            start_time,
            end_time
        ),

    CONSTRAINT fk_employee_availability_org_user
        FOREIGN KEY (organization_id, user_id)
        REFERENCES public.organization_users (
            organization_id,
            user_id
        )
);

--------------------------------------------------------------------
------------------services.employee_availability_exceptions
--------------------------------------------------------------------

CREATE TABLE services.employee_availability_exceptions (
    employee_availability_exception_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    exception_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    exception_type VARCHAR(20) NOT NULL,

    reason TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_employee_availability_exception_time
        CHECK (start_time < end_time),

    CONSTRAINT chk_employee_availability_exception_type
        CHECK (exception_type IN ('unavailable', 'available')),

    CONSTRAINT uq_employee_availability_exception
        UNIQUE (
            organization_id,
            user_id,
            exception_date,
            start_time,
            end_time,
            exception_type
        ),

    CONSTRAINT fk_employee_availability_exception_org_user
        FOREIGN KEY (organization_id, user_id)
        REFERENCES public.organization_users (
            organization_id,
            user_id
        )
);

-------------------------------------------------------------------
------------------services.appointment_statuses
-------------------------------------------------------------------

CREATE TABLE services.appointment_statuses (
    appointment_status_id BIGSERIAL PRIMARY KEY,

    status_code VARCHAR(50) NOT NULL UNIQUE,
    status_name VARCHAR(100) NOT NULL,
    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
--------------------------------------------------------------------
---------------------------services.appointment table
--------------------------------------------------------------------

CREATE TABLE services.appointments (
    appointment_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    service_order_id BIGINT NOT NULL,

    customer_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,

    appointment_status_id BIGINT NOT NULL,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_appointments_time
        CHECK (start_at < end_at),

    CONSTRAINT fk_appointments_org_service_order
        FOREIGN KEY (organization_id, service_order_id)
        REFERENCES services.service_orders (
            organization_id,
            service_order_id
        ),

    CONSTRAINT fk_appointments_org_customer
        FOREIGN KEY (organization_id, customer_id)
        REFERENCES public.customers (
            organization_id,
            customer_id
        ),

    CONSTRAINT fk_appointments_org_user
        FOREIGN KEY (organization_id, user_id)
        REFERENCES public.organization_users (
            organization_id,
            user_id
        ),

    CONSTRAINT fk_appointments_status
        FOREIGN KEY (appointment_status_id)
        REFERENCES services.appointment_statuses (
            appointment_status_id
        )
);
--------------------------------------------------------------------
------------------------services.appointment_items table
--------------------------------------------------------------------

CREATE TABLE services.appointment_items (
    appointment_item_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    service_order_id BIGINT NOT NULL,

    appointment_id BIGINT NOT NULL,
    service_order_item_id BIGINT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_appointment_items_order_item
        UNIQUE (
            organization_id,
            appointment_id,
            service_order_item_id
        ),

    CONSTRAINT fk_appointment_items_appointment
        FOREIGN KEY (
            organization_id,
            service_order_id,
            appointment_id
        )
        REFERENCES services.appointments (
            organization_id,
            service_order_id,
            appointment_id
        ),

    CONSTRAINT fk_appointment_items_service_item
        FOREIGN KEY (
            organization_id,
            service_order_id,
            service_order_item_id
        )
        REFERENCES services.service_order_items (
            organization_id,
            service_order_id,
            service_order_item_id
        )
);
------------------------------------------------------------
-----------service.service_inventory_consumptions table
------------------------------------------------------------
CREATE TABLE services.service_inventory_consumptions (
    service_inventory_consumption_id BIGSERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    service_order_item_id BIGINT NOT NULL,
    warehouse_id INTEGER NOT NULL,
    consumed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_service_inventory_consumption_item
        UNIQUE (organization_id, service_order_item_id),

    CONSTRAINT fk_service_inventory_consumption_item
        FOREIGN KEY (organization_id, service_order_item_id)
        REFERENCES services.service_order_items (
            organization_id,
            service_order_item_id
        )
        ON DELETE RESTRICT,

    CONSTRAINT fk_service_inventory_consumption_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES public.warehouses (warehouse_id)
        ON DELETE RESTRICT
);
---------------------------------------------------------------
---------------services.validate_appointment_availabilty function
--------------------------------------------------------------
CREATE OR REPLACE FUNCTION services.validate_appointment_availability()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    appointment_day SMALLINT;
    appointment_date DATE;
    appointment_start TIME;
    appointment_end TIME;

    has_normal_availability BOOLEAN;
    has_available_exception BOOLEAN;
    has_unavailable_exception BOOLEAN;
BEGIN
    -- Only enforce availability for active appointment states.
    IF NEW.appointment_status_id NOT IN (1, 2) THEN
        RETURN NEW;
    END IF;

    appointment_day :=
        EXTRACT(DOW FROM NEW.start_at)::SMALLINT;

    appointment_date :=
        NEW.start_at::DATE;

    appointment_start :=
        NEW.start_at::TIME;

    appointment_end :=
        NEW.end_at::TIME;

    -- Prevent appointments spanning multiple calendar dates
    -- in this first scheduling model.
    IF NEW.start_at::DATE <> NEW.end_at::DATE THEN
        RAISE EXCEPTION
            'Appointment must begin and end on the same date';
    END IF;

    -- Check normal recurring availability.
    SELECT EXISTS (
        SELECT 1
        FROM services.employee_availability ea
        WHERE ea.organization_id = NEW.organization_id
          AND ea.user_id = NEW.user_id
          AND ea.day_of_week = appointment_day
          AND ea.is_active = TRUE
          AND appointment_start >= ea.start_time
          AND appointment_end <= ea.end_time
    )
    INTO has_normal_availability;

    -- Check for explicit added availability.
    SELECT EXISTS (
        SELECT 1
        FROM services.employee_availability_exceptions eae
        WHERE eae.organization_id = NEW.organization_id
          AND eae.user_id = NEW.user_id
          AND eae.exception_date = appointment_date
          AND eae.exception_type = 'available'
          AND appointment_start >= eae.start_time
          AND appointment_end <= eae.end_time
    )
    INTO has_available_exception;

    -- Check whether unavailable time overlaps the appointment.
    SELECT EXISTS (
        SELECT 1
        FROM services.employee_availability_exceptions eae
        WHERE eae.organization_id = NEW.organization_id
          AND eae.user_id = NEW.user_id
          AND eae.exception_date = appointment_date
          AND eae.exception_type = 'unavailable'
          AND appointment_start < eae.end_time
          AND appointment_end > eae.start_time
    )
    INTO has_unavailable_exception;

    IF NOT has_normal_availability
       AND NOT has_available_exception THEN
        RAISE EXCEPTION
            'Employee % is not available for appointment from % to %',
            NEW.user_id,
            NEW.start_at,
            NEW.end_at;
    END IF;

    IF has_unavailable_exception THEN
        RAISE EXCEPTION
            'Employee % has an unavailable exception during appointment time',
            NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$;
---------------------------------------------------------------
------------------services.start_services function
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION services.start_service(
    p_organization_id INTEGER,
    p_appointment_id BIGINT,
    p_service_order_item_id BIGINT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_appointment_status VARCHAR;
    v_item_status VARCHAR;
    v_service_id BIGINT;
    v_employee_user_id INTEGER;
    v_in_progress_status_id BIGINT;
BEGIN
    /*
     * 1. Verify the appointment exists and get the
     *    assigned employee + current appointment status.
     */
    SELECT
        aps.status_code,
        a.user_id
    INTO
        v_appointment_status,
        v_employee_user_id
    FROM services.appointments a
    JOIN services.appointment_statuses aps
        ON aps.appointment_status_id = a.appointment_status_id
    WHERE a.organization_id = p_organization_id
      AND a.appointment_id = p_appointment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Appointment % not found for organization %',
            p_appointment_id,
            p_organization_id;
    END IF;

    /*
     * 2. The appointment itself must already be started.
     */
    IF v_appointment_status <> 'in_progress' THEN
        RAISE EXCEPTION
            'Service cannot be started because appointment % is currently %',
            p_appointment_id,
            v_appointment_status;
    END IF;

    /*
     * 3. Verify this service-order item is actually
     *    attached to this appointment.
     */
    SELECT
        soi.service_id,
        sois.status_code
    INTO
        v_service_id,
        v_item_status
    FROM services.appointment_items ai
    JOIN services.service_order_items soi
        ON soi.organization_id = ai.organization_id
       AND soi.service_order_id = ai.service_order_id
       AND soi.service_order_item_id = ai.service_order_item_id
    JOIN services.service_order_item_statuses sois
        ON sois.service_order_item_status_id =
           soi.service_order_item_status_id
    WHERE ai.organization_id = p_organization_id
      AND ai.appointment_id = p_appointment_id
      AND ai.service_order_item_id = p_service_order_item_id
    FOR UPDATE OF soi;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service order item % is not attached to appointment %',
            p_service_order_item_id,
            p_appointment_id;
    END IF;

    /*
     * 4. Only pending or scheduled services may start.
     */
    IF v_item_status NOT IN ('pending', 'scheduled') THEN
        RAISE EXCEPTION
            'Service order item % cannot be started from status %',
            p_service_order_item_id,
            v_item_status;
    END IF;

    /*
     * 5. Verify the appointment employee is authorized
     *    to perform this particular service.
     */
    IF NOT EXISTS (
        SELECT 1
        FROM services.employee_services es
        WHERE es.organization_id = p_organization_id
          AND es.user_id = v_employee_user_id
          AND es.service_id = v_service_id
          AND es.is_active = TRUE
    ) THEN
        RAISE EXCEPTION
            'Employee % is not authorized to perform service %',
            v_employee_user_id,
            v_service_id;
    END IF;

    /*
     * 6. Get the in_progress status ID.
     */
    SELECT service_order_item_status_id
    INTO v_in_progress_status_id
    FROM services.service_order_item_statuses
    WHERE status_code = 'in_progress';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service-order-item status in_progress does not exist';
    END IF;

    /*
     * 7. Start this individual service.
     */
    UPDATE services.service_order_items
    SET
        service_order_item_status_id = v_in_progress_status_id,
        started_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE organization_id = p_organization_id
      AND service_order_item_id = p_service_order_item_id;
END;
$$;
-------------------------------------------------------------
------------services.complete_service function
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION services.complete_service(
    p_organization_id INTEGER,
    p_appointment_id BIGINT,
    p_service_order_item_id BIGINT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_item_status VARCHAR;
    v_completed_status_id BIGINT;
BEGIN
    /*
     * 1. Verify the service item is attached
     *    to the appointment and lock it.
     */
    SELECT
        sois.status_code
    INTO
        v_item_status
    FROM services.appointment_items ai
    JOIN services.service_order_items soi
        ON soi.organization_id = ai.organization_id
       AND soi.service_order_id = ai.service_order_id
       AND soi.service_order_item_id = ai.service_order_item_id
    JOIN services.service_order_item_statuses sois
        ON sois.service_order_item_status_id =
           soi.service_order_item_status_id
    WHERE ai.organization_id = p_organization_id
      AND ai.appointment_id = p_appointment_id
      AND ai.service_order_item_id = p_service_order_item_id
    FOR UPDATE OF soi;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service order item % is not attached to appointment %',
            p_service_order_item_id,
            p_appointment_id;
    END IF;

    /*
     * 2. Only an in-progress service may be completed.
     */
    IF v_item_status <> 'in_progress' THEN
        RAISE EXCEPTION
            'Service order item % cannot be completed from status %',
            p_service_order_item_id,
            v_item_status;
    END IF;

    /*
     * 3. Get the completed status ID.
     */
    SELECT service_order_item_status_id
    INTO v_completed_status_id
    FROM services.service_order_item_statuses
    WHERE status_code = 'completed';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service-order-item status completed does not exist';
    END IF;

    /*
     * 4. Complete the service.
     */
    UPDATE services.service_order_items
    SET
        service_order_item_status_id = v_completed_status_id,
        completed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE organization_id = p_organization_id
      AND service_order_item_id = p_service_order_item_id;
END;
$$;

--------------------------------------------------------------
------------services.consume_service_inventory function 
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION services.consume_service_inventory(
    p_organization_id INTEGER,
    p_service_order_item_id BIGINT,
    p_warehouse_id INTEGER,
    p_performed_by_user_id INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_service_id BIGINT;
    v_item_status VARCHAR;
    v_requirement RECORD;
    v_quantity_available INTEGER;
BEGIN
    /*
     * 1. Lock and validate the service-order item.
     */
    SELECT
        soi.service_id,
        sois.status_code
    INTO
        v_service_id,
        v_item_status
    FROM services.service_order_items soi
    JOIN services.service_order_item_statuses sois
        ON sois.service_order_item_status_id =
           soi.service_order_item_status_id
    WHERE soi.organization_id = p_organization_id
      AND soi.service_order_item_id = p_service_order_item_id
    FOR UPDATE OF soi;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service order item % not found for organization %',
            p_service_order_item_id,
            p_organization_id;
    END IF;

    /*
     * 2. Inventory may only be consumed for a completed service.
     */
    IF v_item_status <> 'completed' THEN
        RAISE EXCEPTION
            'Inventory cannot be consumed because service order item % is currently %',
            p_service_order_item_id,
            v_item_status;
    END IF;

    /*
     * 3. Prevent duplicate consumption.
     */
    IF EXISTS (
        SELECT 1
        FROM services.service_inventory_consumptions sic
        WHERE sic.organization_id = p_organization_id
          AND sic.service_order_item_id = p_service_order_item_id
    ) THEN
        RAISE EXCEPTION
            'Inventory has already been consumed for service order item %',
            p_service_order_item_id;
    END IF;

    /*
     * 4. Validate warehouse belongs to the same organization.
     */
    IF NOT EXISTS (
        SELECT 1
        FROM public.warehouses w
        WHERE w.warehouse_id = p_warehouse_id
          AND w.organization_id = p_organization_id
          AND w.is_active = TRUE
    ) THEN
        RAISE EXCEPTION
            'Warehouse % is not an active warehouse for organization %',
            p_warehouse_id,
            p_organization_id;
    END IF;

    /*
     * 5. Check every inventory requirement before changing stock.
     */
    FOR v_requirement IN
        SELECT
            sir.variant_id,
            sir.quantity_required
        FROM services.service_inventory_requirements sir
        WHERE sir.organization_id = p_organization_id
          AND sir.service_id = v_service_id
          AND sir.is_active = TRUE
    LOOP
        SELECT
            wi.quantity_on_hand - wi.quantity_reserved
        INTO
            v_quantity_available
        FROM public.warehouse_inventory wi
        WHERE wi.warehouse_id = p_warehouse_id
          AND wi.variant_id = v_requirement.variant_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Variant % is not stocked in warehouse %',
                v_requirement.variant_id,
                p_warehouse_id;
        END IF;

        IF v_quantity_available < v_requirement.quantity_required THEN
            RAISE EXCEPTION
                'Insufficient inventory for variant %. Required %, available %',
                v_requirement.variant_id,
                v_requirement.quantity_required,
                v_quantity_available;
        END IF;
    END LOOP;

    /*
     * 6. Deduct stock and record transactions.
     */
    FOR v_requirement IN
        SELECT
            sir.variant_id,
            sir.quantity_required
        FROM services.service_inventory_requirements sir
        WHERE sir.organization_id = p_organization_id
          AND sir.service_id = v_service_id
          AND sir.is_active = TRUE
    LOOP
        UPDATE public.warehouse_inventory
        SET
            quantity_on_hand =
                quantity_on_hand - v_requirement.quantity_required,
            updated_at = CURRENT_TIMESTAMP
        WHERE warehouse_id = p_warehouse_id
          AND variant_id = v_requirement.variant_id;

        INSERT INTO public.inventory_transactions (
            variant_id,
            transaction_type,
            quantity_change,
            notes,
            organization_id,
            warehouse_id,
            performed_by_user_id,
            reference_type,
            reference_id
        )
        VALUES (
            v_requirement.variant_id,
            'STOCK_OUT',
            -v_requirement.quantity_required,
            'Service inventory consumption',
            p_organization_id,
            p_warehouse_id,
            p_performed_by_user_id,
            'SERVICE_ORDER_ITEM',
            p_service_order_item_id
        );
    END LOOP;

    /*
     * 7. Mark this service item as consumed.
     */
    INSERT INTO services.service_inventory_consumptions (
        organization_id,
        service_order_item_id,
        warehouse_id
    )
    VALUES (
        p_organization_id,
        p_service_order_item_id,
        p_warehouse_id
    );
END;
$$;
--------------------------------------------------------------
-----------------------service.cancel_service function 
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION services.cancel_service(
    p_organization_id INTEGER,
    p_appointment_id BIGINT,
    p_service_order_item_id BIGINT,
    p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_item_status VARCHAR;
    v_cancelled_status_id BIGINT;
BEGIN
    /*
     * 1. Verify the item is attached to the appointment
     *    and lock the service-order item.
     */
    SELECT
        sois.status_code
    INTO
        v_item_status
    FROM services.appointment_items ai
    JOIN services.service_order_items soi
        ON soi.organization_id = ai.organization_id
       AND soi.service_order_id = ai.service_order_id
       AND soi.service_order_item_id = ai.service_order_item_id
    JOIN services.service_order_item_statuses sois
        ON sois.service_order_item_status_id =
           soi.service_order_item_status_id
    WHERE ai.organization_id = p_organization_id
      AND ai.appointment_id = p_appointment_id
      AND ai.service_order_item_id = p_service_order_item_id
    FOR UPDATE OF soi;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service order item % is not attached to appointment %',
            p_service_order_item_id,
            p_appointment_id;
    END IF;

    /*
     * 2. Only active/uncompleted service states may be cancelled.
     */
    IF v_item_status NOT IN ('pending', 'scheduled', 'in_progress') THEN
        RAISE EXCEPTION
            'Service order item % cannot be cancelled from status %',
            p_service_order_item_id,
            v_item_status;
    END IF;

    /*
     * 3. Get the cancelled status ID.
     */
    SELECT service_order_item_status_id
    INTO v_cancelled_status_id
    FROM services.service_order_item_statuses
    WHERE status_code = 'cancelled';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service-order-item status cancelled does not exist';
    END IF;

    /*
     * 4. Cancel the service.
     */
    UPDATE services.service_order_items
    SET
        service_order_item_status_id = v_cancelled_status_id,
        cancelled_at = CURRENT_TIMESTAMP,
        cancellation_reason = p_reason,
        updated_at = CURRENT_TIMESTAMP
    WHERE organization_id = p_organization_id
      AND service_order_item_id = p_service_order_item_id;
END;
$$;
--------------------------------------------------------------
--------services.cancel_service_order function 
--------------------------------------------------------------

CREATE OR REPLACE FUNCTION services.cancel_service_order(
    p_organization_id INTEGER,
    p_service_order_id BIGINT,
    p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_status VARCHAR;
    v_cancelled_order_status_id BIGINT;
    v_cancelled_item_status_id BIGINT;
BEGIN
    /*
     * 1. Lock and validate the service order.
     */
    SELECT sos.status_code
    INTO v_order_status
    FROM services.service_orders so
    JOIN services.service_order_statuses sos
      ON sos.service_order_status_id = so.service_order_status_id
    WHERE so.organization_id = p_organization_id
      AND so.service_order_id = p_service_order_id
    FOR UPDATE OF so;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service order % not found for organization %',
            p_service_order_id,
            p_organization_id;
    END IF;

    /*
     * 2. Reject terminal order states.
     */
    IF v_order_status IN ('completed', 'cancelled') THEN
        RAISE EXCEPTION
            'Service order % cannot be cancelled from status %',
            p_service_order_id,
            v_order_status;
    END IF;

    /*
     * 3. A completed child service blocks whole-order cancellation.
     */
    IF EXISTS (
        SELECT 1
        FROM services.service_order_items soi
        JOIN services.service_order_item_statuses sois
          ON sois.service_order_item_status_id =
             soi.service_order_item_status_id
        WHERE soi.organization_id = p_organization_id
          AND soi.service_order_id = p_service_order_id
          AND sois.status_code = 'completed'
    ) THEN
        RAISE EXCEPTION
            'Service order % cannot be cancelled because it contains a completed service item',
            p_service_order_id;
    END IF;

    /*
     * 4. Get cancelled status IDs.
     */
    SELECT service_order_status_id
    INTO v_cancelled_order_status_id
    FROM services.service_order_statuses
    WHERE status_code = 'cancelled';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service-order status cancelled does not exist';
    END IF;

    SELECT service_order_item_status_id
    INTO v_cancelled_item_status_id
    FROM services.service_order_item_statuses
    WHERE status_code = 'cancelled';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service-order-item status cancelled does not exist';
    END IF;

    /*
     * 5. Cancel all remaining active service items.
     */
    UPDATE services.service_order_items soi
    SET
        service_order_item_status_id = v_cancelled_item_status_id,
        cancelled_at = CURRENT_TIMESTAMP,
        cancellation_reason = p_reason,
        updated_at = CURRENT_TIMESTAMP
    FROM services.service_order_item_statuses sois
    WHERE sois.service_order_item_status_id =
          soi.service_order_item_status_id
      AND soi.organization_id = p_organization_id
      AND soi.service_order_id = p_service_order_id
      AND sois.status_code IN ('pending', 'scheduled', 'in_progress');

    /*
     * 6. Cancel the parent service order.
     */
    UPDATE services.service_orders
    SET
        service_order_status_id = v_cancelled_order_status_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE organization_id = p_organization_id
      AND service_order_id = p_service_order_id;
END;
$$;

--------------------------------------------------------------
-----------services.mark_no_show
--------------------------------------------------------------
CREATE OR REPLACE FUNCTION services.mark_no_show(
    p_organization_id INTEGER,
    p_appointment_id BIGINT,
    p_changed_by_user_id INTEGER,
    p_initiated_by VARCHAR,
    p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_appointment_status VARCHAR;
    v_no_show_appointment_status_id BIGINT;
    v_no_show_item_status_id BIGINT;
BEGIN
    /*
     * 1. Lock and validate the appointment.
     */
    SELECT aps.status_code
    INTO v_appointment_status
    FROM services.appointments a
    JOIN services.appointment_statuses aps
      ON aps.appointment_status_id = a.appointment_status_id
    WHERE a.organization_id = p_organization_id
      AND a.appointment_id = p_appointment_id
    FOR UPDATE OF a;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Appointment % not found for organization %',
            p_appointment_id,
            p_organization_id;
    END IF;

    /*
     * 2. Only scheduled appointments can become no-show.
     */
    IF v_appointment_status <> 'scheduled' THEN
        RAISE EXCEPTION
            'Appointment % cannot be marked no-show from status %',
            p_appointment_id,
            v_appointment_status;
    END IF;

    /*
     * 3. Get no-show status IDs.
     */
    SELECT appointment_status_id
    INTO v_no_show_appointment_status_id
    FROM services.appointment_statuses
    WHERE status_code = 'no_show';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Appointment status no_show does not exist';
    END IF;

    SELECT service_order_item_status_id
    INTO v_no_show_item_status_id
    FROM services.service_order_item_statuses
    WHERE status_code = 'no_show';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Service-order-item status no_show does not exist';
    END IF;

    /*
     * 4. Mark eligible attached service items as no-show.
     */
    UPDATE services.service_order_items soi
    SET
        service_order_item_status_id = v_no_show_item_status_id,
        no_show_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    FROM services.appointment_items ai,
         services.service_order_item_statuses sois
    WHERE ai.organization_id = p_organization_id
      AND ai.appointment_id = p_appointment_id
      AND ai.service_order_item_id = soi.service_order_item_id
      AND ai.organization_id = soi.organization_id
      AND sois.service_order_item_status_id =
          soi.service_order_item_status_id
      AND sois.status_code IN ('pending', 'scheduled');

    /*
     * 5. Change the appointment status using the approved function.
     */
    PERFORM services.change_appointment_status(
        p_organization_id,
        p_appointment_id,
        'no_show',
        p_changed_by_user_id,
        p_initiated_by,
        p_reason
    );
END;
$$;

---------------------------------------------------------------
----------------trg_validate_appointment-trigger
--------------------------------------------------------------
CREATE TRIGGER trg_validate_appointment_availability
BEFORE INSERT OR UPDATE OF
    organization_id,
    user_id,
    start_at,
    end_at,
    appointment_status_id
ON services.appointments
FOR EACH ROW
EXECUTE FUNCTION services.validate_appointment_availability();

----------------------------------------------------------------
-------------- services.appointment_events
----------------------------------------------------------------
CREATE TABLE services.appointment_events (
    appointment_event_id BIGSERIAL PRIMARY KEY,

    organization_id INTEGER NOT NULL,
    appointment_id BIGINT NOT NULL,

    event_type VARCHAR(50) NOT NULL,

    old_start_at TIMESTAMPTZ,
    old_end_at TIMESTAMPTZ,

    new_start_at TIMESTAMPTZ,
    new_end_at TIMESTAMPTZ,

    changed_by_user_id INTEGER,
    reason TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_appointment_events_type
        CHECK (
            event_type IN (
                'scheduled',
                'rescheduled',
                'started',
                'completed',
                'cancelled',
                'no_show'
            )
        ),

    CONSTRAINT fk_appointment_events_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES services.appointments(appointment_id),

    CONSTRAINT fk_appointment_events_changed_by
        FOREIGN KEY (changed_by_user_id)
        REFERENCES public.users(user_id)
);
---------------------------------------------------------------
--------------services.rescheduled_appointment function
--------------------------------------------------------------
CREATE OR REPLACE FUNCTION services.reschedule_appointment(
    p_organization_id INTEGER,
    p_appointment_id BIGINT,
    p_new_start_at TIMESTAMPTZ,
    p_new_end_at TIMESTAMPTZ,
    p_changed_by_user_id INTEGER,
    p_initiated_by VARCHAR,
    p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_start_at TIMESTAMPTZ;
    v_old_end_at TIMESTAMPTZ;
    v_status_code VARCHAR;
BEGIN
    IF p_initiated_by NOT IN (
        'customer',
        'employee',
        'manager',
        'system'
    ) THEN
        RAISE EXCEPTION
            'Invalid initiated_by value: %',
            p_initiated_by;
    END IF;

    SELECT
        a.start_at,
        a.end_at,
        s.status_code
    INTO
        v_old_start_at,
        v_old_end_at,
        v_status_code
    FROM services.appointments a
    JOIN services.appointment_statuses s
        ON s.appointment_status_id = a.appointment_status_id
    WHERE a.organization_id = p_organization_id
      AND a.appointment_id = p_appointment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Appointment % not found for organization %',
            p_appointment_id,
            p_organization_id;
    END IF;

    IF v_status_code <> 'scheduled' THEN
        RAISE EXCEPTION
            'Only scheduled appointments may be rescheduled. Current status: %',
            v_status_code;
    END IF;

    UPDATE services.appointments
    SET
        start_at = p_new_start_at,
        end_at = p_new_end_at,
        updated_at = CURRENT_TIMESTAMP
    WHERE organization_id = p_organization_id
      AND appointment_id = p_appointment_id;

    INSERT INTO services.appointment_events (
        organization_id,
        appointment_id,
        event_type,
        old_start_at,
        old_end_at,
        new_start_at,
        new_end_at,
        changed_by_user_id,
        initiated_by,
        reason
    )
    VALUES (
        p_organization_id,
        p_appointment_id,
        'rescheduled',
        v_old_start_at,
        v_old_end_at,
        p_new_start_at,
        p_new_end_at,
        p_changed_by_user_id,
        p_initiated_by,
        p_reason
    );
END;
$$;
-------------------------------------------------------------
-----------------services.change_appointment_status_function
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION services.change_appointment_status(
    p_organization_id INTEGER,
    p_appointment_id BIGINT,
    p_new_status_code VARCHAR,
    p_changed_by_user_id INTEGER,
    p_initiated_by VARCHAR,
    p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status_code VARCHAR;
    v_new_status_id BIGINT;
    v_event_type VARCHAR;
BEGIN
    IF p_initiated_by NOT IN (
        'customer',
        'employee',
        'manager',
        'system'
    ) THEN
        RAISE EXCEPTION
            'Invalid initiated_by value: %',
            p_initiated_by;
    END IF;

    SELECT
        s.status_code
    INTO
        v_old_status_code
    FROM services.appointments a
    JOIN services.appointment_statuses s
        ON s.appointment_status_id = a.appointment_status_id
    WHERE a.organization_id = p_organization_id
      AND a.appointment_id = p_appointment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Appointment % not found for organization %',
            p_appointment_id,
            p_organization_id;
    END IF;

    SELECT appointment_status_id
    INTO v_new_status_id
    FROM services.appointment_statuses
    WHERE status_code = p_new_status_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Invalid appointment status code: %',
            p_new_status_code;
    END IF;

    IF NOT (
        (v_old_status_code = 'scheduled'
            AND p_new_status_code IN ('in_progress', 'cancelled', 'no_show'))
        OR
        (v_old_status_code = 'in_progress'
            AND p_new_status_code IN ('completed', 'cancelled'))
    ) THEN
        RAISE EXCEPTION
            'Invalid appointment status transition: % -> %',
            v_old_status_code,
            p_new_status_code;
    END IF;

    PERFORM set_config(
        'services.allow_appointment_status_change',
        'on',
        true
    );

    UPDATE services.appointments
    SET
        appointment_status_id = v_new_status_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE organization_id = p_organization_id
      AND appointment_id = p_appointment_id;

    PERFORM set_config(
        'services.allow_appointment_status_change',
        'off',
        true
    );

    v_event_type :=
        CASE
            WHEN p_new_status_code = 'in_progress' THEN 'started'
            ELSE p_new_status_code
        END;

    INSERT INTO services.appointment_events (
        organization_id,
        appointment_id,
        event_type,
        changed_by_user_id,
        initiated_by,
        reason
    )
    VALUES (
        p_organization_id,
        p_appointment_id,
        v_event_type,
        p_changed_by_user_id,
        p_initiated_by,
        p_reason
    );
END;
$$;
----------------------------------------------------------------------
-----------------------
----------------------------------------------------------------------


-----------------------------------------------------------------------
---------------------services.guard_appointment_status_update function 
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION services.guard_appointment_status_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.appointment_status_id IS DISTINCT FROM OLD.appointment_status_id THEN
        IF current_setting(
            'services.allow_appointment_status_change',
            true
        ) IS DISTINCT FROM 'on' THEN
            RAISE EXCEPTION
                'Appointment status must be changed through services.change_appointment_status()';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;
--------------------------------------------------------------
------------------trg_guard_appointment_status_update-trigger
--------------------------------------------------------------
CREATE TRIGGER trg_guard_appointment_status_update
BEFORE UPDATE OF appointment_status_id
ON services.appointments
FOR EACH ROW
EXECUTE FUNCTION services.guard_appointment_status_update();

---------------------------------------------------------------
---------------extension
---------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS btree_gist;

--------------------------------------------------------------------
------------------------ Alterations
--------------------------------------------------------------------
ALTER TABLE public.products
ADD CONSTRAINT uq_products_org_product
    UNIQUE (organization_id, product_id);

ALTER TABLE public.product_variants
ADD CONSTRAINT uq_product_variants_product_variant
    UNIQUE (product_id, variant_id);

ALTER TABLE services.employee_services
ADD CONSTRAINT fk_employee_services_org_service
    FOREIGN KEY (organization_id, service_id)
    REFERENCES services.services (
        organization_id,
        service_id
    );

	ALTER TABLE services.services
ADD CONSTRAINT uq_services_org_service
    UNIQUE (organization_id, service_id);

	ALTER TABLE services.employee_services
ADD CONSTRAINT fk_employee_services_org_user
    FOREIGN KEY (organization_id, user_id)
    REFERENCES public.organization_users (
        organization_id,
        user_id
    );

	ALTER TABLE public.invoices
DROP CONSTRAINT invoices_booking_id_fkey;

ALTER TABLE public.quotes
DROP CONSTRAINT quotes_booking_id_fkey;

ALTER TABLE public.bookings
DROP CONSTRAINT bookings_package_id_fkey;

ALTER TABLE public.invoice_items
DROP CONSTRAINT invoice_items_service_id_fkey;

ALTER TABLE public.quote_items
DROP CONSTRAINT quote_items_service_id_fkey;

ALTER TABLE public.customers
ADD CONSTRAINT uq_customers_org_customer
    UNIQUE (organization_id, customer_id);

	ALTER TABLE services.service_orders
ADD CONSTRAINT uq_service_orders_org_service_order
    UNIQUE (organization_id, service_order_id);

	ALTER TABLE services.appointments
ADD CONSTRAINT uq_appointments_org_order_appointment
    UNIQUE (
        organization_id,
        service_order_id,
        appointment_id
    );

	ALTER TABLE services.service_order_items
ADD CONSTRAINT uq_service_order_items_org_order_item
    UNIQUE (
        organization_id,
        service_order_id,
        service_order_item_id
    );

ALTER TABLE services.appointments
ADD CONSTRAINT ex_appointments_employee_time_overlap
EXCLUDE USING gist (
    organization_id WITH =,
    user_id WITH =,
    tstzrange(start_at, end_at, '[)') WITH &&
)
WHERE (appointment_status_id IN (1, 2));