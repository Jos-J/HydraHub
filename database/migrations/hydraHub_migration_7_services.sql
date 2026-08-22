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
------------------------services.appointment_items
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