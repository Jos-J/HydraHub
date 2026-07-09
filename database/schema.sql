--
-- PostgreSQL database dump
--

\restrict VY6yw5DisOffLa1ipTpCkJAHPdywaN5Ec5BaZJQC5jR4AlEOnVDWEfg5wbwL1SR

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.4

-- Started on 2026-07-09 00:12:47

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 288 (class 1255 OID 19266)
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: jos
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO jos;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 255 (class 1259 OID 19331)
-- Name: addresses; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.addresses (
    address_id integer NOT NULL,
    customer_id integer,
    address_type character varying(30) NOT NULL,
    street_line1 character varying(255) NOT NULL,
    street_line2 character varying(255),
    city character varying(100) NOT NULL,
    state character varying(100),
    postal_code character varying(20),
    country character varying(100) DEFAULT 'USA'::character varying,
    is_default boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.addresses OWNER TO jos;

--
-- TOC entry 254 (class 1259 OID 19330)
-- Name: addresses_address_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.addresses_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.addresses_address_id_seq OWNER TO jos;

--
-- TOC entry 5464 (class 0 OID 0)
-- Dependencies: 254
-- Name: addresses_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.addresses_address_id_seq OWNED BY public.addresses.address_id;


--
-- TOC entry 278 (class 1259 OID 19647)
-- Name: booking_items; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.booking_items (
    booking_item_id integer NOT NULL,
    booking_id integer NOT NULL,
    service_id integer,
    product_id integer,
    item_name character varying(150),
    description text,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price numeric(10,2) DEFAULT 0.00 NOT NULL,
    line_total numeric(10,2) GENERATED ALWAYS AS (((quantity)::numeric * unit_price)) STORED,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_booking_item CHECK (((service_id IS NOT NULL) OR (product_id IS NOT NULL) OR (item_name IS NOT NULL)))
);


ALTER TABLE public.booking_items OWNER TO jos;

--
-- TOC entry 277 (class 1259 OID 19646)
-- Name: booking_items_booking_item_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.booking_items_booking_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.booking_items_booking_item_id_seq OWNER TO jos;

--
-- TOC entry 5465 (class 0 OID 0)
-- Dependencies: 277
-- Name: booking_items_booking_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.booking_items_booking_item_id_seq OWNED BY public.booking_items.booking_item_id;


--
-- TOC entry 263 (class 1259 OID 19403)
-- Name: bookings; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.bookings (
    booking_id integer NOT NULL,
    customer_id integer NOT NULL,
    package_id integer,
    event_date date NOT NULL,
    event_time time without time zone,
    guest_count integer,
    venue_name character varying(150),
    venue_address text,
    status character varying(30) DEFAULT 'pending'::character varying,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.bookings OWNER TO jos;

--
-- TOC entry 262 (class 1259 OID 19402)
-- Name: bookings_booking_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.bookings_booking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bookings_booking_id_seq OWNER TO jos;

--
-- TOC entry 5466 (class 0 OID 0)
-- Dependencies: 262
-- Name: bookings_booking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.bookings_booking_id_seq OWNED BY public.bookings.booking_id;


--
-- TOC entry 220 (class 1259 OID 18963)
-- Name: categories; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.categories (
    category_id integer NOT NULL,
    category_code character varying(20),
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.categories OWNER TO jos;

--
-- TOC entry 219 (class 1259 OID 18962)
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_category_id_seq OWNER TO jos;

--
-- TOC entry 5467 (class 0 OID 0)
-- Dependencies: 219
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.categories_category_id_seq OWNED BY public.categories.category_id;


--
-- TOC entry 240 (class 1259 OID 19166)
-- Name: customers; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.customers (
    customer_id integer NOT NULL,
    customer_code character varying(30),
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    email character varying(100),
    phone character varying(20),
    address text,
    city character varying(100),
    state character varying(100),
    postal_code character varying(20),
    country character varying(100),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.customers OWNER TO jos;

--
-- TOC entry 239 (class 1259 OID 19165)
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customers_customer_id_seq OWNER TO jos;

--
-- TOC entry 5468 (class 0 OID 0)
-- Dependencies: 239
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.customers_customer_id_seq OWNED BY public.customers.customer_id;


--
-- TOC entry 226 (class 1259 OID 19023)
-- Name: inventory_transactions; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.inventory_transactions (
    transaction_id integer NOT NULL,
    variant_id integer NOT NULL,
    transaction_type character varying(20) NOT NULL,
    quantity integer NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_transaction_type CHECK (((transaction_type)::text = ANY ((ARRAY['STOCK_IN'::character varying, 'STOCK_OUT'::character varying, 'ADJUSTMENT'::character varying])::text[])))
);


ALTER TABLE public.inventory_transactions OWNER TO jos;

--
-- TOC entry 225 (class 1259 OID 19022)
-- Name: inventory_transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.inventory_transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_transactions_transaction_id_seq OWNER TO jos;

--
-- TOC entry 5469 (class 0 OID 0)
-- Dependencies: 225
-- Name: inventory_transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.inventory_transactions_transaction_id_seq OWNED BY public.inventory_transactions.transaction_id;


--
-- TOC entry 271 (class 1259 OID 19513)
-- Name: invoice_items; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.invoice_items (
    invoice_item_id integer NOT NULL,
    invoice_id integer NOT NULL,
    product_id integer,
    service_id integer,
    description text,
    quantity integer DEFAULT 1,
    unit_price numeric(10,2) DEFAULT 0,
    line_total numeric(10,2) DEFAULT 0
);


ALTER TABLE public.invoice_items OWNER TO jos;

--
-- TOC entry 270 (class 1259 OID 19512)
-- Name: invoice_items_invoice_item_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.invoice_items_invoice_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_items_invoice_item_id_seq OWNER TO jos;

--
-- TOC entry 5470 (class 0 OID 0)
-- Dependencies: 270
-- Name: invoice_items_invoice_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.invoice_items_invoice_item_id_seq OWNED BY public.invoice_items.invoice_item_id;


--
-- TOC entry 269 (class 1259 OID 19480)
-- Name: invoices; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.invoices (
    invoice_id integer NOT NULL,
    customer_id integer NOT NULL,
    booking_id integer,
    sales_order_id integer,
    invoice_number character varying(50) NOT NULL,
    subtotal numeric(10,2) DEFAULT 0,
    tax numeric(10,2) DEFAULT 0,
    discount numeric(10,2) DEFAULT 0,
    total numeric(10,2) DEFAULT 0,
    status character varying(30) DEFAULT 'unpaid'::character varying,
    due_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.invoices OWNER TO jos;

--
-- TOC entry 268 (class 1259 OID 19479)
-- Name: invoices_invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.invoices_invoice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoices_invoice_id_seq OWNER TO jos;

--
-- TOC entry 5471 (class 0 OID 0)
-- Dependencies: 268
-- Name: invoices_invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.invoices_invoice_id_seq OWNED BY public.invoices.invoice_id;


--
-- TOC entry 261 (class 1259 OID 19380)
-- Name: package_services; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.package_services (
    package_service_id integer NOT NULL,
    package_id integer NOT NULL,
    service_id integer NOT NULL,
    quantity integer DEFAULT 1
);


ALTER TABLE public.package_services OWNER TO jos;

--
-- TOC entry 260 (class 1259 OID 19379)
-- Name: package_services_package_service_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.package_services_package_service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.package_services_package_service_id_seq OWNER TO jos;

--
-- TOC entry 5472 (class 0 OID 0)
-- Dependencies: 260
-- Name: package_services_package_service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.package_services_package_service_id_seq OWNED BY public.package_services.package_service_id;


--
-- TOC entry 273 (class 1259 OID 19542)
-- Name: payments; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.payments (
    payment_id integer NOT NULL,
    customer_id integer NOT NULL,
    invoice_id integer,
    amount numeric(10,2) NOT NULL,
    payment_method character varying(50),
    payment_status character varying(30) DEFAULT 'pending'::character varying,
    transaction_reference character varying(150),
    payment_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.payments OWNER TO jos;

--
-- TOC entry 272 (class 1259 OID 19541)
-- Name: payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.payments_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_payment_id_seq OWNER TO jos;

--
-- TOC entry 5473 (class 0 OID 0)
-- Dependencies: 272
-- Name: payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.payments_payment_id_seq OWNED BY public.payments.payment_id;


--
-- TOC entry 249 (class 1259 OID 19271)
-- Name: permissions; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.permissions (
    permission_id integer NOT NULL,
    name character varying(100) NOT NULL,
    module character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.permissions OWNER TO jos;

--
-- TOC entry 248 (class 1259 OID 19270)
-- Name: permissions_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.permissions_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissions_permission_id_seq OWNER TO jos;

--
-- TOC entry 5474 (class 0 OID 0)
-- Dependencies: 248
-- Name: permissions_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.permissions_permission_id_seq OWNED BY public.permissions.permission_id;


--
-- TOC entry 224 (class 1259 OID 19002)
-- Name: product_variants; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.product_variants (
    variant_id integer NOT NULL,
    product_id integer NOT NULL,
    sku character varying(50) NOT NULL,
    size character varying(10),
    color character varying(50),
    price numeric(10,2),
    stock_quantity integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_variants OWNER TO jos;

--
-- TOC entry 222 (class 1259 OID 18980)
-- Name: products; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.products (
    product_id integer NOT NULL,
    category_id integer,
    product_code character varying(30),
    name character varying(150) NOT NULL,
    description text,
    base_price numeric(10,2) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.products OWNER TO jos;

--
-- TOC entry 247 (class 1259 OID 19262)
-- Name: product_inventory_view; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.product_inventory_view AS
 SELECT p.product_id,
    p.name AS product_name,
    pv.variant_id,
    pv.sku,
    pv.size,
    pv.color,
    pv.stock_quantity
   FROM (public.products p
     JOIN public.product_variants pv ON ((p.product_id = pv.product_id)));


ALTER VIEW public.product_inventory_view OWNER TO jos;

--
-- TOC entry 230 (class 1259 OID 19060)
-- Name: product_suppliers; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.product_suppliers (
    product_supplier_id integer NOT NULL,
    product_id integer NOT NULL,
    supplier_id integer NOT NULL,
    supplier_product_code character varying(50),
    unit_cost numeric(10,2),
    is_primary boolean DEFAULT false
);


ALTER TABLE public.product_suppliers OWNER TO jos;

--
-- TOC entry 229 (class 1259 OID 19059)
-- Name: product_suppliers_product_supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.product_suppliers_product_supplier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_suppliers_product_supplier_id_seq OWNER TO jos;

--
-- TOC entry 5475 (class 0 OID 0)
-- Dependencies: 229
-- Name: product_suppliers_product_supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.product_suppliers_product_supplier_id_seq OWNED BY public.product_suppliers.product_supplier_id;


--
-- TOC entry 223 (class 1259 OID 19001)
-- Name: product_variants_variant_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.product_variants_variant_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_variants_variant_id_seq OWNER TO jos;

--
-- TOC entry 5476 (class 0 OID 0)
-- Dependencies: 223
-- Name: product_variants_variant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.product_variants_variant_id_seq OWNED BY public.product_variants.variant_id;


--
-- TOC entry 221 (class 1259 OID 18979)
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.products_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_product_id_seq OWNER TO jos;

--
-- TOC entry 5477 (class 0 OID 0)
-- Dependencies: 221
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.products_product_id_seq OWNED BY public.products.product_id;


--
-- TOC entry 234 (class 1259 OID 19103)
-- Name: purchase_order_items; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.purchase_order_items (
    purchase_order_item_id integer CONSTRAINT purchase_order_times_purchase_order_item_id_not_null NOT NULL,
    purchase_order_id integer CONSTRAINT purchase_order_times_purchase_order_id_not_null NOT NULL,
    variant_id integer CONSTRAINT purchase_order_times_variant_id_not_null NOT NULL,
    quantity integer CONSTRAINT purchase_order_times_quanity_not_null NOT NULL,
    unit_cost numeric(10,2) CONSTRAINT purchase_order_times_unit_cost_not_null NOT NULL,
    line_cost numeric(12,2) CONSTRAINT purchase_order_times_line_cost_not_null NOT NULL,
    received_quantity integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_purchase_item_cost CHECK ((unit_cost >= (0)::numeric)),
    CONSTRAINT chk_purchase_item_quantity CHECK ((quantity > 0))
);


ALTER TABLE public.purchase_order_items OWNER TO jos;

--
-- TOC entry 233 (class 1259 OID 19102)
-- Name: purchase_order_times_purchase_order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.purchase_order_times_purchase_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.purchase_order_times_purchase_order_item_id_seq OWNER TO jos;

--
-- TOC entry 5478 (class 0 OID 0)
-- Dependencies: 233
-- Name: purchase_order_times_purchase_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.purchase_order_times_purchase_order_item_id_seq OWNED BY public.purchase_order_items.purchase_order_item_id;


--
-- TOC entry 232 (class 1259 OID 19081)
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.purchase_orders (
    purchase_order_id integer NOT NULL,
    supplier_id integer NOT NULL,
    order_date date DEFAULT CURRENT_DATE,
    expected_delivery_date date,
    status character varying(30) DEFAULT 'DRAFT'::character varying,
    total_amount numeric(12,2) DEFAULT 0,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_purchase_order_status CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'ORDERED'::character varying, 'RECEIVED'::character varying, 'CANCELLED'::character varying])::text[])))
);


ALTER TABLE public.purchase_orders OWNER TO jos;

--
-- TOC entry 231 (class 1259 OID 19080)
-- Name: purchase_orders_purchase_order_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.purchase_orders_purchase_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.purchase_orders_purchase_order_id_seq OWNER TO jos;

--
-- TOC entry 5479 (class 0 OID 0)
-- Dependencies: 231
-- Name: purchase_orders_purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.purchase_orders_purchase_order_id_seq OWNED BY public.purchase_orders.purchase_order_id;


--
-- TOC entry 267 (class 1259 OID 19455)
-- Name: quote_items; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.quote_items (
    quote_item_id integer NOT NULL,
    quote_id integer NOT NULL,
    service_id integer,
    description text,
    quantity integer DEFAULT 1,
    unit_price numeric(10,2) DEFAULT 0,
    line_total numeric(10,2) DEFAULT 0
);


ALTER TABLE public.quote_items OWNER TO jos;

--
-- TOC entry 266 (class 1259 OID 19454)
-- Name: quote_items_quote_item_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.quote_items_quote_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quote_items_quote_item_id_seq OWNER TO jos;

--
-- TOC entry 5480 (class 0 OID 0)
-- Dependencies: 266
-- Name: quote_items_quote_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.quote_items_quote_item_id_seq OWNED BY public.quote_items.quote_item_id;


--
-- TOC entry 265 (class 1259 OID 19427)
-- Name: quotes; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.quotes (
    quote_id integer NOT NULL,
    customer_id integer NOT NULL,
    booking_id integer,
    quote_number character varying(50) NOT NULL,
    subtotal numeric(10,2) DEFAULT 0,
    tax numeric(10,2) DEFAULT 0,
    discount numeric(10,2) DEFAULT 0,
    total numeric(10,2) DEFAULT 0,
    status character varying(30) DEFAULT 'draft'::character varying,
    expires_on date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.quotes OWNER TO jos;

--
-- TOC entry 264 (class 1259 OID 19426)
-- Name: quotes_quote_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.quotes_quote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quotes_quote_id_seq OWNER TO jos;

--
-- TOC entry 5481 (class 0 OID 0)
-- Dependencies: 264
-- Name: quotes_quote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.quotes_quote_id_seq OWNED BY public.quotes.quote_id;


--
-- TOC entry 253 (class 1259 OID 19309)
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.role_permissions (
    role_permission_id integer NOT NULL,
    role_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.role_permissions OWNER TO jos;

--
-- TOC entry 252 (class 1259 OID 19308)
-- Name: role_permissions_role_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.role_permissions_role_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_permissions_role_permission_id_seq OWNER TO jos;

--
-- TOC entry 5482 (class 0 OID 0)
-- Dependencies: 252
-- Name: role_permissions_role_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.role_permissions_role_permission_id_seq OWNED BY public.role_permissions.role_permission_id;


--
-- TOC entry 236 (class 1259 OID 19128)
-- Name: roles; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    role_name character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.roles OWNER TO jos;

--
-- TOC entry 235 (class 1259 OID 19127)
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_role_id_seq OWNER TO jos;

--
-- TOC entry 5483 (class 0 OID 0)
-- Dependencies: 235
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- TOC entry 246 (class 1259 OID 19225)
-- Name: sales_order_items; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.sales_order_items (
    sales_order_item_id integer NOT NULL,
    sales_order_id integer NOT NULL,
    variant_id integer NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    line_total numeric(12,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_sales_item_price CHECK ((unit_price >= (0)::numeric)),
    CONSTRAINT chk_sales_item_quantity CHECK ((quantity > 0))
);


ALTER TABLE public.sales_order_items OWNER TO jos;

--
-- TOC entry 245 (class 1259 OID 19224)
-- Name: sales_order_items_sales_order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.sales_order_items_sales_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_order_items_sales_order_item_id_seq OWNER TO jos;

--
-- TOC entry 5484 (class 0 OID 0)
-- Dependencies: 245
-- Name: sales_order_items_sales_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.sales_order_items_sales_order_item_id_seq OWNED BY public.sales_order_items.sales_order_item_id;


--
-- TOC entry 244 (class 1259 OID 19203)
-- Name: sales_orders; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.sales_orders (
    sales_order_id integer NOT NULL,
    customer_id integer NOT NULL,
    order_date date DEFAULT CURRENT_DATE,
    status character varying(30) DEFAULT 'PENDING'::character varying,
    total_amount numeric(12,2) DEFAULT 0,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_sales_order_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'PAID'::character varying, 'SHIPPED'::character varying, 'CANCELLED'::character varying])::text[])))
);


ALTER TABLE public.sales_orders OWNER TO jos;

--
-- TOC entry 243 (class 1259 OID 19202)
-- Name: sales_orders_sales_order_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.sales_orders_sales_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_orders_sales_order_id_seq OWNER TO jos;

--
-- TOC entry 5485 (class 0 OID 0)
-- Dependencies: 243
-- Name: sales_orders_sales_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.sales_orders_sales_order_id_seq OWNED BY public.sales_orders.sales_order_id;


--
-- TOC entry 276 (class 1259 OID 19616)
-- Name: service_package_items; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.service_package_items (
    package_item_id integer NOT NULL,
    package_id integer NOT NULL,
    service_id integer,
    product_id integer,
    description text,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT service_package_items_check CHECK (((service_id IS NOT NULL) OR (product_id IS NOT NULL) OR (description IS NOT NULL)))
);


ALTER TABLE public.service_package_items OWNER TO jos;

--
-- TOC entry 275 (class 1259 OID 19615)
-- Name: service_package_items_package_item_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.service_package_items_package_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_package_items_package_item_id_seq OWNER TO jos;

--
-- TOC entry 5486 (class 0 OID 0)
-- Dependencies: 275
-- Name: service_package_items_package_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.service_package_items_package_item_id_seq OWNED BY public.service_package_items.package_item_id;


--
-- TOC entry 259 (class 1259 OID 19366)
-- Name: service_packages; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.service_packages (
    package_id integer NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    package_price numeric(10,2) DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.service_packages OWNER TO jos;

--
-- TOC entry 258 (class 1259 OID 19365)
-- Name: service_packages_package_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.service_packages_package_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_packages_package_id_seq OWNER TO jos;

--
-- TOC entry 5487 (class 0 OID 0)
-- Dependencies: 258
-- Name: service_packages_package_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.service_packages_package_id_seq OWNED BY public.service_packages.package_id;


--
-- TOC entry 257 (class 1259 OID 19352)
-- Name: services; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.services (
    service_id integer NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    base_price numeric(10,2) DEFAULT 0,
    duration_minutes integer,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.services OWNER TO jos;

--
-- TOC entry 256 (class 1259 OID 19351)
-- Name: services_service_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.services_service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.services_service_id_seq OWNER TO jos;

--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 256
-- Name: services_service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.services_service_id_seq OWNED BY public.services.service_id;


--
-- TOC entry 228 (class 1259 OID 19044)
-- Name: suppliers; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.suppliers (
    supplier_id integer NOT NULL,
    supplier_code character varying(20),
    company_name character varying(150) NOT NULL,
    contact_name character varying(100),
    email character varying(100),
    phone character varying(20),
    address text,
    city character varying(100),
    state character varying(100),
    postal_code character varying(20),
    country character varying(100),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.suppliers OWNER TO jos;

--
-- TOC entry 227 (class 1259 OID 19043)
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.suppliers_supplier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.suppliers_supplier_id_seq OWNER TO jos;

--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 227
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.suppliers_supplier_id_seq OWNED BY public.suppliers.supplier_id;


--
-- TOC entry 251 (class 1259 OID 19286)
-- Name: user_roles; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.user_roles (
    user_role_id integer NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_roles OWNER TO jos;

--
-- TOC entry 250 (class 1259 OID 19285)
-- Name: user_roles_user_role_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.user_roles_user_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_roles_user_role_id_seq OWNER TO jos;

--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 250
-- Name: user_roles_user_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.user_roles_user_role_id_seq OWNED BY public.user_roles.user_role_id;


--
-- TOC entry 238 (class 1259 OID 19142)
-- Name: users; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    role_id integer,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password_hash text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO jos;

--
-- TOC entry 237 (class 1259 OID 19141)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO jos;

--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 237
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- TOC entry 281 (class 1259 OID 19689)
-- Name: vw_booking_details; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.vw_booking_details AS
 SELECT b.booking_id,
    c.customer_code,
    c.first_name,
    c.last_name,
    sp.name AS package_name,
    b.event_date,
    b.event_time,
    b.guest_count,
    b.venue_name,
    b.venue_address,
    b.status,
    b.notes,
    b.created_at
   FROM ((public.bookings b
     JOIN public.customers c ON ((b.customer_id = c.customer_id)))
     LEFT JOIN public.service_packages sp ON ((b.package_id = sp.package_id)));


ALTER VIEW public.vw_booking_details OWNER TO jos;

--
-- TOC entry 279 (class 1259 OID 19679)
-- Name: vw_booking_items; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.vw_booking_items AS
 SELECT bi.booking_item_id,
    bi.booking_id,
    COALESCE(s.name, p.name, bi.item_name, (bi.description)::character varying) AS item_name,
        CASE
            WHEN (s.service_id IS NOT NULL) THEN 'service'::text
            WHEN (p.product_id IS NOT NULL) THEN 'product'::text
            ELSE 'custom'::text
        END AS item_type,
    bi.quantity,
    bi.unit_price,
    bi.line_total
   FROM ((public.booking_items bi
     LEFT JOIN public.services s ON ((bi.service_id = s.service_id)))
     LEFT JOIN public.products p ON ((bi.product_id = p.product_id)));


ALTER VIEW public.vw_booking_items OWNER TO jos;

--
-- TOC entry 280 (class 1259 OID 19684)
-- Name: vw_customer_summary; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.vw_customer_summary AS
 SELECT c.customer_id,
    c.customer_code,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.city,
    c.state,
    count(DISTINCT so.sales_order_id) AS total_orders,
    count(DISTINCT b.booking_id) AS total_bookings,
    count(DISTINCT i.invoice_id) AS total_invoices,
    COALESCE(sum(DISTINCT so.total_amount), (0)::numeric) AS total_sales
   FROM (((public.customers c
     LEFT JOIN public.sales_orders so ON ((c.customer_id = so.customer_id)))
     LEFT JOIN public.bookings b ON ((c.customer_id = b.customer_id)))
     LEFT JOIN public.invoices i ON ((c.customer_id = i.customer_id)))
  GROUP BY c.customer_id, c.customer_code, c.first_name, c.last_name, c.email, c.phone, c.city, c.state;


ALTER VIEW public.vw_customer_summary OWNER TO jos;

--
-- TOC entry 286 (class 1259 OID 19715)
-- Name: warehouse_inventory; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.warehouse_inventory (
    warehouse_inventory_id integer NOT NULL,
    warehouse_id integer NOT NULL,
    variant_id integer NOT NULL,
    quantity_on_hand integer DEFAULT 0 NOT NULL,
    quantity_reserved integer DEFAULT 0 NOT NULL,
    reorder_level integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.warehouse_inventory OWNER TO jos;

--
-- TOC entry 242 (class 1259 OID 19186)
-- Name: warehouses; Type: TABLE; Schema: public; Owner: jos
--

CREATE TABLE public.warehouses (
    warehouse_id integer NOT NULL,
    warehouse_code character varying(30) NOT NULL,
    name character varying(100) NOT NULL,
    address text,
    city character varying(100),
    state character varying(100),
    postal_code character varying(20),
    country character varying(100),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.warehouses OWNER TO jos;

--
-- TOC entry 287 (class 1259 OID 19744)
-- Name: vw_inventory_stock; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.vw_inventory_stock AS
 SELECT wi.warehouse_inventory_id,
    w.warehouse_id,
    w.warehouse_code,
    w.name AS warehouse_name,
    pv.variant_id,
    p.product_id,
    p.product_code,
    p.name AS product_name,
    pv.sku,
    pv.size,
    pv.color,
    c.name AS category_name,
    wi.quantity_on_hand,
    wi.quantity_reserved,
    (wi.quantity_on_hand - wi.quantity_reserved) AS quantity_available,
    wi.reorder_level,
        CASE
            WHEN (wi.quantity_on_hand <= 0) THEN 'out_of_stock'::text
            WHEN (wi.quantity_on_hand <= wi.reorder_level) THEN 'low_stock'::text
            ELSE 'in_stock'::text
        END AS stock_status,
    pv.price,
    p.is_active AS product_active,
    pv.is_active AS variant_active
   FROM ((((public.warehouse_inventory wi
     JOIN public.warehouses w ON ((wi.warehouse_id = w.warehouse_id)))
     JOIN public.product_variants pv ON ((wi.variant_id = pv.variant_id)))
     JOIN public.products p ON ((pv.product_id = p.product_id)))
     LEFT JOIN public.categories c ON ((p.category_id = c.category_id)));


ALTER VIEW public.vw_inventory_stock OWNER TO jos;

--
-- TOC entry 282 (class 1259 OID 19694)
-- Name: vw_invoice_balance; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.vw_invoice_balance AS
 SELECT i.invoice_id,
    i.invoice_number,
    i.customer_id,
    c.first_name,
    c.last_name,
    i.booking_id,
    i.sales_order_id,
    i.subtotal,
    i.tax,
    i.discount,
    i.total AS invoice_total,
    COALESCE(sum(p.amount), (0)::numeric) AS amount_paid,
    (i.total - COALESCE(sum(p.amount), (0)::numeric)) AS balance_due,
    i.status,
    i.due_date,
    i.created_at
   FROM ((public.invoices i
     JOIN public.customers c ON ((i.customer_id = c.customer_id)))
     LEFT JOIN public.payments p ON ((i.invoice_id = p.invoice_id)))
  GROUP BY i.invoice_id, i.invoice_number, i.customer_id, c.first_name, c.last_name, i.booking_id, i.sales_order_id, i.subtotal, i.tax, i.discount, i.total, i.status, i.due_date, i.created_at;


ALTER VIEW public.vw_invoice_balance OWNER TO jos;

--
-- TOC entry 274 (class 1259 OID 19578)
-- Name: vw_package_services; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.vw_package_services AS
 SELECT sp.package_id,
    sp.name AS package_name,
    s.service_id,
    s.name AS service_name,
    ps.quantity,
    s.base_price
   FROM ((public.service_packages sp
     JOIN public.package_services ps ON ((sp.package_id = ps.package_id)))
     JOIN public.services s ON ((ps.service_id = s.service_id)));


ALTER VIEW public.vw_package_services OWNER TO jos;

--
-- TOC entry 284 (class 1259 OID 19704)
-- Name: vw_products; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.vw_products AS
 SELECT p.product_id,
    p.product_code,
    p.name AS product_name,
    p.description,
    p.base_price,
    p.is_active,
    c.category_id,
    c.name AS category_name,
    p.created_at,
    p.updated_at
   FROM (public.products p
     LEFT JOIN public.categories c ON ((p.category_id = c.category_id)));


ALTER VIEW public.vw_products OWNER TO jos;

--
-- TOC entry 283 (class 1259 OID 19699)
-- Name: vw_sales_orders; Type: VIEW; Schema: public; Owner: jos
--

CREATE VIEW public.vw_sales_orders AS
 SELECT so.sales_order_id,
    so.customer_id,
    c.customer_code,
    c.first_name,
    c.last_name,
    so.order_date,
    so.status,
    so.total_amount,
    so.notes,
    so.created_at
   FROM (public.sales_orders so
     JOIN public.customers c ON ((so.customer_id = c.customer_id)));


ALTER VIEW public.vw_sales_orders OWNER TO jos;

--
-- TOC entry 285 (class 1259 OID 19714)
-- Name: warehouse_inventory_warehouse_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.warehouse_inventory_warehouse_inventory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.warehouse_inventory_warehouse_inventory_id_seq OWNER TO jos;

--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 285
-- Name: warehouse_inventory_warehouse_inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.warehouse_inventory_warehouse_inventory_id_seq OWNED BY public.warehouse_inventory.warehouse_inventory_id;


--
-- TOC entry 241 (class 1259 OID 19185)
-- Name: warehouses_warehouse_id_seq; Type: SEQUENCE; Schema: public; Owner: jos
--

CREATE SEQUENCE public.warehouses_warehouse_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.warehouses_warehouse_id_seq OWNER TO jos;

--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 241
-- Name: warehouses_warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jos
--

ALTER SEQUENCE public.warehouses_warehouse_id_seq OWNED BY public.warehouses.warehouse_id;


--
-- TOC entry 5095 (class 2604 OID 19334)
-- Name: addresses address_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.addresses ALTER COLUMN address_id SET DEFAULT nextval('public.addresses_address_id_seq'::regclass);


--
-- TOC entry 5141 (class 2604 OID 19650)
-- Name: booking_items booking_item_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.booking_items ALTER COLUMN booking_item_id SET DEFAULT nextval('public.booking_items_booking_item_id_seq'::regclass);


--
-- TOC entry 5109 (class 2604 OID 19406)
-- Name: bookings booking_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.bookings ALTER COLUMN booking_id SET DEFAULT nextval('public.bookings_booking_id_seq'::regclass);


--
-- TOC entry 5038 (class 2604 OID 18966)
-- Name: categories category_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.categories ALTER COLUMN category_id SET DEFAULT nextval('public.categories_category_id_seq'::regclass);


--
-- TOC entry 5074 (class 2604 OID 19169)
-- Name: customers customer_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.customers ALTER COLUMN customer_id SET DEFAULT nextval('public.customers_customer_id_seq'::regclass);


--
-- TOC entry 5051 (class 2604 OID 19026)
-- Name: inventory_transactions transaction_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.inventory_transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.inventory_transactions_transaction_id_seq'::regclass);


--
-- TOC entry 5130 (class 2604 OID 19516)
-- Name: invoice_items invoice_item_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoice_items ALTER COLUMN invoice_item_id SET DEFAULT nextval('public.invoice_items_invoice_item_id_seq'::regclass);


--
-- TOC entry 5123 (class 2604 OID 19483)
-- Name: invoices invoice_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoices ALTER COLUMN invoice_id SET DEFAULT nextval('public.invoices_invoice_id_seq'::regclass);


--
-- TOC entry 5107 (class 2604 OID 19383)
-- Name: package_services package_service_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.package_services ALTER COLUMN package_service_id SET DEFAULT nextval('public.package_services_package_service_id_seq'::regclass);


--
-- TOC entry 5134 (class 2604 OID 19545)
-- Name: payments payment_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.payments ALTER COLUMN payment_id SET DEFAULT nextval('public.payments_payment_id_seq'::regclass);


--
-- TOC entry 5090 (class 2604 OID 19274)
-- Name: permissions permission_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.permissions ALTER COLUMN permission_id SET DEFAULT nextval('public.permissions_permission_id_seq'::regclass);


--
-- TOC entry 5057 (class 2604 OID 19063)
-- Name: product_suppliers product_supplier_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.product_suppliers ALTER COLUMN product_supplier_id SET DEFAULT nextval('public.product_suppliers_product_supplier_id_seq'::regclass);


--
-- TOC entry 5046 (class 2604 OID 19005)
-- Name: product_variants variant_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.product_variants ALTER COLUMN variant_id SET DEFAULT nextval('public.product_variants_variant_id_seq'::regclass);


--
-- TOC entry 5042 (class 2604 OID 18983)
-- Name: products product_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.products ALTER COLUMN product_id SET DEFAULT nextval('public.products_product_id_seq'::regclass);


--
-- TOC entry 5065 (class 2604 OID 19106)
-- Name: purchase_order_items purchase_order_item_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.purchase_order_items ALTER COLUMN purchase_order_item_id SET DEFAULT nextval('public.purchase_order_times_purchase_order_item_id_seq'::regclass);


--
-- TOC entry 5059 (class 2604 OID 19084)
-- Name: purchase_orders purchase_order_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.purchase_orders ALTER COLUMN purchase_order_id SET DEFAULT nextval('public.purchase_orders_purchase_order_id_seq'::regclass);


--
-- TOC entry 5119 (class 2604 OID 19458)
-- Name: quote_items quote_item_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quote_items ALTER COLUMN quote_item_id SET DEFAULT nextval('public.quote_items_quote_item_id_seq'::regclass);


--
-- TOC entry 5112 (class 2604 OID 19430)
-- Name: quotes quote_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quotes ALTER COLUMN quote_id SET DEFAULT nextval('public.quotes_quote_id_seq'::regclass);


--
-- TOC entry 5094 (class 2604 OID 19312)
-- Name: role_permissions role_permission_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN role_permission_id SET DEFAULT nextval('public.role_permissions_role_permission_id_seq'::regclass);


--
-- TOC entry 5068 (class 2604 OID 19131)
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- TOC entry 5088 (class 2604 OID 19228)
-- Name: sales_order_items sales_order_item_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.sales_order_items ALTER COLUMN sales_order_item_id SET DEFAULT nextval('public.sales_order_items_sales_order_item_id_seq'::regclass);


--
-- TOC entry 5082 (class 2604 OID 19206)
-- Name: sales_orders sales_order_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.sales_orders ALTER COLUMN sales_order_id SET DEFAULT nextval('public.sales_orders_sales_order_id_seq'::regclass);


--
-- TOC entry 5137 (class 2604 OID 19619)
-- Name: service_package_items package_item_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.service_package_items ALTER COLUMN package_item_id SET DEFAULT nextval('public.service_package_items_package_item_id_seq'::regclass);


--
-- TOC entry 5103 (class 2604 OID 19369)
-- Name: service_packages package_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.service_packages ALTER COLUMN package_id SET DEFAULT nextval('public.service_packages_package_id_seq'::regclass);


--
-- TOC entry 5099 (class 2604 OID 19355)
-- Name: services service_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.services ALTER COLUMN service_id SET DEFAULT nextval('public.services_service_id_seq'::regclass);


--
-- TOC entry 5053 (class 2604 OID 19047)
-- Name: suppliers supplier_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN supplier_id SET DEFAULT nextval('public.suppliers_supplier_id_seq'::regclass);


--
-- TOC entry 5092 (class 2604 OID 19289)
-- Name: user_roles user_role_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN user_role_id SET DEFAULT nextval('public.user_roles_user_role_id_seq'::regclass);


--
-- TOC entry 5070 (class 2604 OID 19145)
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- TOC entry 5146 (class 2604 OID 19718)
-- Name: warehouse_inventory warehouse_inventory_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.warehouse_inventory ALTER COLUMN warehouse_inventory_id SET DEFAULT nextval('public.warehouse_inventory_warehouse_inventory_id_seq'::regclass);


--
-- TOC entry 5078 (class 2604 OID 19189)
-- Name: warehouses warehouse_id; Type: DEFAULT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.warehouses ALTER COLUMN warehouse_id SET DEFAULT nextval('public.warehouses_warehouse_id_seq'::regclass);


--
-- TOC entry 5226 (class 2606 OID 19345)
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (address_id);


--
-- TOC entry 5254 (class 2606 OID 19663)
-- Name: booking_items booking_items_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.booking_items
    ADD CONSTRAINT booking_items_pkey PRIMARY KEY (booking_item_id);


--
-- TOC entry 5236 (class 2606 OID 19415)
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (booking_id);


--
-- TOC entry 5162 (class 2606 OID 18976)
-- Name: categories categories_category_code_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_category_code_key UNIQUE (category_code);


--
-- TOC entry 5164 (class 2606 OID 18974)
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 5197 (class 2606 OID 19181)
-- Name: customers customers_customer_code_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_customer_code_key UNIQUE (customer_code);


--
-- TOC entry 5199 (class 2606 OID 19183)
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- TOC entry 5201 (class 2606 OID 19179)
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- TOC entry 5177 (class 2606 OID 19036)
-- Name: inventory_transactions inventory_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.inventory_transactions
    ADD CONSTRAINT inventory_transactions_pkey PRIMARY KEY (transaction_id);


--
-- TOC entry 5248 (class 2606 OID 19525)
-- Name: invoice_items invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (invoice_item_id);


--
-- TOC entry 5244 (class 2606 OID 19496)
-- Name: invoices invoices_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_invoice_number_key UNIQUE (invoice_number);


--
-- TOC entry 5246 (class 2606 OID 19494)
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (invoice_id);


--
-- TOC entry 5232 (class 2606 OID 19391)
-- Name: package_services package_services_package_id_service_id_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_package_id_service_id_key UNIQUE (package_id, service_id);


--
-- TOC entry 5234 (class 2606 OID 19389)
-- Name: package_services package_services_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_pkey PRIMARY KEY (package_service_id);


--
-- TOC entry 5250 (class 2606 OID 19552)
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 5214 (class 2606 OID 19284)
-- Name: permissions permissions_name_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_name_key UNIQUE (name);


--
-- TOC entry 5216 (class 2606 OID 19282)
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (permission_id);


--
-- TOC entry 5183 (class 2606 OID 19069)
-- Name: product_suppliers product_suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_pkey PRIMARY KEY (product_supplier_id);


--
-- TOC entry 5172 (class 2606 OID 19014)
-- Name: product_variants product_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_pkey PRIMARY KEY (variant_id);


--
-- TOC entry 5174 (class 2606 OID 19016)
-- Name: product_variants product_variants_sku_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_sku_key UNIQUE (sku);


--
-- TOC entry 5167 (class 2606 OID 18993)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- TOC entry 5169 (class 2606 OID 18995)
-- Name: products products_product_code_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_product_code_key UNIQUE (product_code);


--
-- TOC entry 5187 (class 2606 OID 19116)
-- Name: purchase_order_items purchase_order_times_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchase_order_times_pkey PRIMARY KEY (purchase_order_item_id);


--
-- TOC entry 5185 (class 2606 OID 19096)
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (purchase_order_id);


--
-- TOC entry 5242 (class 2606 OID 19467)
-- Name: quote_items quote_items_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quote_items
    ADD CONSTRAINT quote_items_pkey PRIMARY KEY (quote_item_id);


--
-- TOC entry 5238 (class 2606 OID 19441)
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (quote_id);


--
-- TOC entry 5240 (class 2606 OID 19443)
-- Name: quotes quotes_quote_number_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_quote_number_key UNIQUE (quote_number);


--
-- TOC entry 5222 (class 2606 OID 19317)
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_permission_id);


--
-- TOC entry 5224 (class 2606 OID 19319)
-- Name: role_permissions role_permissions_role_id_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_permission_id_key UNIQUE (role_id, permission_id);


--
-- TOC entry 5189 (class 2606 OID 19138)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 5191 (class 2606 OID 19140)
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- TOC entry 5212 (class 2606 OID 19237)
-- Name: sales_order_items sales_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_pkey PRIMARY KEY (sales_order_item_id);


--
-- TOC entry 5208 (class 2606 OID 19218)
-- Name: sales_orders sales_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_pkey PRIMARY KEY (sales_order_id);


--
-- TOC entry 5252 (class 2606 OID 19630)
-- Name: service_package_items service_package_items_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.service_package_items
    ADD CONSTRAINT service_package_items_pkey PRIMARY KEY (package_item_id);


--
-- TOC entry 5230 (class 2606 OID 19378)
-- Name: service_packages service_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.service_packages
    ADD CONSTRAINT service_packages_pkey PRIMARY KEY (package_id);


--
-- TOC entry 5228 (class 2606 OID 19364)
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (service_id);


--
-- TOC entry 5179 (class 2606 OID 19056)
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (supplier_id);


--
-- TOC entry 5181 (class 2606 OID 19058)
-- Name: suppliers suppliers_supplier_code_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_supplier_code_key UNIQUE (supplier_code);


--
-- TOC entry 5218 (class 2606 OID 19295)
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_role_id);


--
-- TOC entry 5220 (class 2606 OID 19297)
-- Name: user_roles user_roles_user_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_id_key UNIQUE (user_id, role_id);


--
-- TOC entry 5193 (class 2606 OID 19159)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 5195 (class 2606 OID 19157)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5256 (class 2606 OID 19731)
-- Name: warehouse_inventory warehouse_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.warehouse_inventory
    ADD CONSTRAINT warehouse_inventory_pkey PRIMARY KEY (warehouse_inventory_id);


--
-- TOC entry 5258 (class 2606 OID 19733)
-- Name: warehouse_inventory warehouse_inventory_warehouse_id_variant_id_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.warehouse_inventory
    ADD CONSTRAINT warehouse_inventory_warehouse_id_variant_id_key UNIQUE (warehouse_id, variant_id);


--
-- TOC entry 5203 (class 2606 OID 19199)
-- Name: warehouses warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (warehouse_id);


--
-- TOC entry 5205 (class 2606 OID 19201)
-- Name: warehouses warehouses_warehouse_code_key; Type: CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_warehouse_code_key UNIQUE (warehouse_code);


--
-- TOC entry 5175 (class 1259 OID 19258)
-- Name: idx_inventory_transactions_variant_id; Type: INDEX; Schema: public; Owner: jos
--

CREATE INDEX idx_inventory_transactions_variant_id ON public.inventory_transactions USING btree (variant_id);


--
-- TOC entry 5170 (class 1259 OID 19257)
-- Name: idx_product_variants_product_id; Type: INDEX; Schema: public; Owner: jos
--

CREATE INDEX idx_product_variants_product_id ON public.product_variants USING btree (product_id);


--
-- TOC entry 5165 (class 1259 OID 19256)
-- Name: idx_products_category_id; Type: INDEX; Schema: public; Owner: jos
--

CREATE INDEX idx_products_category_id ON public.products USING btree (category_id);


--
-- TOC entry 5209 (class 1259 OID 19260)
-- Name: idx_sales_order_items_order_id; Type: INDEX; Schema: public; Owner: jos
--

CREATE INDEX idx_sales_order_items_order_id ON public.sales_order_items USING btree (sales_order_id);


--
-- TOC entry 5210 (class 1259 OID 19261)
-- Name: idx_sales_order_items_variant_id; Type: INDEX; Schema: public; Owner: jos
--

CREATE INDEX idx_sales_order_items_variant_id ON public.sales_order_items USING btree (variant_id);


--
-- TOC entry 5206 (class 1259 OID 19259)
-- Name: idx_sales_orders_customer_id; Type: INDEX; Schema: public; Owner: jos
--

CREATE INDEX idx_sales_orders_customer_id ON public.sales_orders USING btree (customer_id);


--
-- TOC entry 5300 (class 2620 OID 19268)
-- Name: categories trg_categories_updated_at; Type: TRIGGER; Schema: public; Owner: jos
--

CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5302 (class 2620 OID 19269)
-- Name: customers trg_customers_updated_at; Type: TRIGGER; Schema: public; Owner: jos
--

CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5301 (class 2620 OID 19267)
-- Name: products trg_products_updated_at; Type: TRIGGER; Schema: public; Owner: jos
--

CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5275 (class 2606 OID 19346)
-- Name: addresses addresses_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON DELETE CASCADE;


--
-- TOC entry 5278 (class 2606 OID 19416)
-- Name: bookings bookings_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- TOC entry 5279 (class 2606 OID 19421)
-- Name: bookings bookings_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.service_packages(package_id);


--
-- TOC entry 5295 (class 2606 OID 19664)
-- Name: booking_items fk_booking_items_booking; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.booking_items
    ADD CONSTRAINT fk_booking_items_booking FOREIGN KEY (booking_id) REFERENCES public.bookings(booking_id) ON DELETE CASCADE;


--
-- TOC entry 5296 (class 2606 OID 19674)
-- Name: booking_items fk_booking_items_product; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.booking_items
    ADD CONSTRAINT fk_booking_items_product FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE SET NULL;


--
-- TOC entry 5297 (class 2606 OID 19669)
-- Name: booking_items fk_booking_items_service; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.booking_items
    ADD CONSTRAINT fk_booking_items_service FOREIGN KEY (service_id) REFERENCES public.services(service_id) ON DELETE SET NULL;


--
-- TOC entry 5261 (class 2606 OID 19037)
-- Name: inventory_transactions inventory_transactions_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.inventory_transactions
    ADD CONSTRAINT inventory_transactions_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(variant_id);


--
-- TOC entry 5287 (class 2606 OID 19526)
-- Name: invoice_items invoice_items_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(invoice_id) ON DELETE CASCADE;


--
-- TOC entry 5288 (class 2606 OID 19531)
-- Name: invoice_items invoice_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- TOC entry 5289 (class 2606 OID 19536)
-- Name: invoice_items invoice_items_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id);


--
-- TOC entry 5284 (class 2606 OID 19502)
-- Name: invoices invoices_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(booking_id) ON DELETE SET NULL;


--
-- TOC entry 5285 (class 2606 OID 19497)
-- Name: invoices invoices_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- TOC entry 5286 (class 2606 OID 19507)
-- Name: invoices invoices_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_orders(sales_order_id) ON DELETE SET NULL;


--
-- TOC entry 5276 (class 2606 OID 19392)
-- Name: package_services package_services_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.service_packages(package_id) ON DELETE CASCADE;


--
-- TOC entry 5277 (class 2606 OID 19397)
-- Name: package_services package_services_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id) ON DELETE CASCADE;


--
-- TOC entry 5290 (class 2606 OID 19553)
-- Name: payments payments_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- TOC entry 5291 (class 2606 OID 19558)
-- Name: payments payments_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(invoice_id) ON DELETE SET NULL;


--
-- TOC entry 5262 (class 2606 OID 19070)
-- Name: product_suppliers product_suppliers_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- TOC entry 5263 (class 2606 OID 19075)
-- Name: product_suppliers product_suppliers_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id);


--
-- TOC entry 5260 (class 2606 OID 19017)
-- Name: product_variants product_variants_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- TOC entry 5259 (class 2606 OID 18996)
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id);


--
-- TOC entry 5265 (class 2606 OID 19117)
-- Name: purchase_order_items purchase_order_times_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchase_order_times_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_orders(purchase_order_id);


--
-- TOC entry 5266 (class 2606 OID 19122)
-- Name: purchase_order_items purchase_order_times_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchase_order_times_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(variant_id);


--
-- TOC entry 5264 (class 2606 OID 19097)
-- Name: purchase_orders purchase_orders_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id);


--
-- TOC entry 5282 (class 2606 OID 19468)
-- Name: quote_items quote_items_quote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quote_items
    ADD CONSTRAINT quote_items_quote_id_fkey FOREIGN KEY (quote_id) REFERENCES public.quotes(quote_id) ON DELETE CASCADE;


--
-- TOC entry 5283 (class 2606 OID 19473)
-- Name: quote_items quote_items_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quote_items
    ADD CONSTRAINT quote_items_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id);


--
-- TOC entry 5280 (class 2606 OID 19449)
-- Name: quotes quotes_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(booking_id) ON DELETE SET NULL;


--
-- TOC entry 5281 (class 2606 OID 19444)
-- Name: quotes quotes_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- TOC entry 5273 (class 2606 OID 19325)
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(permission_id) ON DELETE CASCADE;


--
-- TOC entry 5274 (class 2606 OID 19320)
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- TOC entry 5269 (class 2606 OID 19238)
-- Name: sales_order_items sales_order_items_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_orders(sales_order_id);


--
-- TOC entry 5270 (class 2606 OID 19243)
-- Name: sales_order_items sales_order_items_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(variant_id);


--
-- TOC entry 5268 (class 2606 OID 19219)
-- Name: sales_orders sales_orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- TOC entry 5292 (class 2606 OID 19631)
-- Name: service_package_items service_package_items_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.service_package_items
    ADD CONSTRAINT service_package_items_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.service_packages(package_id) ON DELETE CASCADE;


--
-- TOC entry 5293 (class 2606 OID 19641)
-- Name: service_package_items service_package_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.service_package_items
    ADD CONSTRAINT service_package_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- TOC entry 5294 (class 2606 OID 19636)
-- Name: service_package_items service_package_items_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.service_package_items
    ADD CONSTRAINT service_package_items_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id);


--
-- TOC entry 5271 (class 2606 OID 19303)
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- TOC entry 5272 (class 2606 OID 19298)
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5267 (class 2606 OID 19160)
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id);


--
-- TOC entry 5298 (class 2606 OID 19739)
-- Name: warehouse_inventory warehouse_inventory_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.warehouse_inventory
    ADD CONSTRAINT warehouse_inventory_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(variant_id) ON DELETE CASCADE;


--
-- TOC entry 5299 (class 2606 OID 19734)
-- Name: warehouse_inventory warehouse_inventory_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jos
--

ALTER TABLE ONLY public.warehouse_inventory
    ADD CONSTRAINT warehouse_inventory_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(warehouse_id) ON DELETE CASCADE;


-- Completed on 2026-07-09 00:12:47

--
-- PostgreSQL database dump complete
--

\unrestrict VY6yw5DisOffLa1ipTpCkJAHPdywaN5Ec5BaZJQC5jR4AlEOnVDWEfg5wbwL1SR

