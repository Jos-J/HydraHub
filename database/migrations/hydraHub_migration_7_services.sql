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

----------------------------------------------------------
------------------------ Alterations
----------------------------------------------------------
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