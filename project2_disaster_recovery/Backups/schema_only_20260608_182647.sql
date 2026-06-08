--
-- PostgreSQL database dump
--

\restrict 09AmqEgrw22heCGkrGDPbLozYFSyC83sXjbdeDCRm8sKQKrGMBJqV4jgPRi6j1j

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

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
-- Name: company; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA company;


ALTER SCHEMA company OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: customers; Type: TABLE; Schema: company; Owner: postgres
--

CREATE TABLE company.customers (
    customer_id integer NOT NULL,
    company_name character varying(100) NOT NULL,
    contact_email character varying(100),
    city character varying(50),
    total_revenue numeric(12,2) DEFAULT 0
);


ALTER TABLE company.customers OWNER TO postgres;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: company; Owner: postgres
--

CREATE SEQUENCE company.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE company.customers_customer_id_seq OWNER TO postgres;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: company; Owner: postgres
--

ALTER SEQUENCE company.customers_customer_id_seq OWNED BY company.customers.customer_id;


--
-- Name: employees; Type: TABLE; Schema: company; Owner: postgres
--

CREATE TABLE company.employees (
    emp_id integer NOT NULL,
    full_name character varying(100) NOT NULL,
    department character varying(50),
    salary numeric(10,2),
    hire_date date DEFAULT CURRENT_DATE
);


ALTER TABLE company.employees OWNER TO postgres;

--
-- Name: employees_emp_id_seq; Type: SEQUENCE; Schema: company; Owner: postgres
--

CREATE SEQUENCE company.employees_emp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE company.employees_emp_id_seq OWNER TO postgres;

--
-- Name: employees_emp_id_seq; Type: SEQUENCE OWNED BY; Schema: company; Owner: postgres
--

ALTER SEQUENCE company.employees_emp_id_seq OWNED BY company.employees.emp_id;


--
-- Name: projects; Type: TABLE; Schema: company; Owner: postgres
--

CREATE TABLE company.projects (
    project_id integer NOT NULL,
    project_name character varying(100) NOT NULL,
    budget numeric(12,2),
    start_date date,
    status character varying(20) DEFAULT 'Aktif'::character varying
);


ALTER TABLE company.projects OWNER TO postgres;

--
-- Name: projects_project_id_seq; Type: SEQUENCE; Schema: company; Owner: postgres
--

CREATE SEQUENCE company.projects_project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE company.projects_project_id_seq OWNER TO postgres;

--
-- Name: projects_project_id_seq; Type: SEQUENCE OWNED BY; Schema: company; Owner: postgres
--

ALTER SEQUENCE company.projects_project_id_seq OWNED BY company.projects.project_id;


--
-- Name: customers customer_id; Type: DEFAULT; Schema: company; Owner: postgres
--

ALTER TABLE ONLY company.customers ALTER COLUMN customer_id SET DEFAULT nextval('company.customers_customer_id_seq'::regclass);


--
-- Name: employees emp_id; Type: DEFAULT; Schema: company; Owner: postgres
--

ALTER TABLE ONLY company.employees ALTER COLUMN emp_id SET DEFAULT nextval('company.employees_emp_id_seq'::regclass);


--
-- Name: projects project_id; Type: DEFAULT; Schema: company; Owner: postgres
--

ALTER TABLE ONLY company.projects ALTER COLUMN project_id SET DEFAULT nextval('company.projects_project_id_seq'::regclass);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: company; Owner: postgres
--

ALTER TABLE ONLY company.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: company; Owner: postgres
--

ALTER TABLE ONLY company.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (emp_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: company; Owner: postgres
--

ALTER TABLE ONLY company.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);


--
-- PostgreSQL database dump complete
--

\unrestrict 09AmqEgrw22heCGkrGDPbLozYFSyC83sXjbdeDCRm8sKQKrGMBJqV4jgPRi6j1j

