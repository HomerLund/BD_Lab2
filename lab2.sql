--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

-- Started on 2024-11-26 14:07:03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 236 (class 1255 OID 16568)
-- Name: delete_table(integer, integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.delete_table(IN start_value integer, IN end_value integer, IN name_table character varying)
    LANGUAGE plpgsql
    AS $$DECLARE
    sql_query TEXT;
    seq TEXT;
	PK TEXT;
BEGIN
	EXECUTE FORMAT(
        'SELECT column_name FROM information_schema.columns WHERE table_name = %L ORDER BY ordinal_position LIMIT 1;',
        name_table
    )
    INTO PK;
	
    -- Видалення записів у таблиці
    sql_query := 'DELETE FROM ' || name_table || 
                 ' WHERE ' || PK || ' BETWEEN ' || start_value || ' AND ' || end_value || ';';
    EXECUTE sql_query;
    
    EXECUTE 'SELECT pg_get_serial_sequence(''' || name_table || ''', ''' || PK || ''')' INTO seq;

    sql_query := 'ALTER SEQUENCE ' || seq || ' RESTART WITH 1;';
    EXECUTE sql_query;
END;$$;


ALTER PROCEDURE public.delete_table(IN start_value integer, IN end_value integer, IN name_table character varying) OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 16586)
-- Name: random_buy(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.random_buy(IN counts integer)
    LANGUAGE plpgsql
    AS $$DECLARE
    random_date DATE;
    random_price DOUBLE PRECISION;
    component_id_random INTEGER;
    factory_id_random INTEGER;
    inserted_count INTEGER := 0;
    existing_count INTEGER;
    last_id INTEGER;
    factory_ids INTEGER[];
    component_ids INTEGER[];
BEGIN
    SELECT ARRAY(SELECT factory_id FROM factory) INTO factory_ids;
    SELECT ARRAY(SELECT component_id FROM components) INTO component_ids;

    SELECT COUNT(*) INTO existing_count FROM buy;
    SELECT COALESCE(MAX(component_id), 0) INTO last_id FROM buy;

    WHILE inserted_count < counts LOOP
        random_date := (timestamp '2024-01-01 00:00:00' + random() * (timestamp '2024-12-30 00:00:00' - timestamp '2024-01-01 00:00:00'))::DATE;
        random_price := random() * 10;

        factory_id_random := factory_ids[FLOOR(random() * array_length(factory_ids, 1) + 1)::INTEGER];
        component_id_random := component_ids[FLOOR(random() * array_length(component_ids, 1) + 1)::INTEGER];

        BEGIN
            INSERT INTO buy (component_id, factory_id, date, price)
            VALUES (
                component_id_random,
                factory_id_random,
                random_date,
                random_price
            );

            inserted_count := inserted_count + 1;
        EXCEPTION
            WHEN foreign_key_violation THEN
                RAISE NOTICE 'Error: all available components have already been purchased';
                EXIT;
            WHEN unique_violation THEN
                CONTINUE;
        END;
    END LOOP;

    RAISE NOTICE 'Total inserted rows: %', inserted_count;
END;$$;


ALTER PROCEDURE public.random_buy(IN counts integer) OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 16598)
-- Name: random_component_category(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.random_component_category(IN counts integer)
    LANGUAGE plpgsql
    AS $$DECLARE
	name_random TEXT;
	random_number INTEGER;
	category_random TEXT;
    inserted_count INTEGER := 0;
	existing_count INTEGER;
	last_id INTEGER;
BEGIN
	SELECT COUNT(*) INTO existing_count FROM component_category;
	
    WHILE inserted_count < counts LOOP
		random_number := FLOOR(RANDOM() * (counts + existing_count + 1 ));
		BEGIN
			INSERT INTO component_category (name, category)
			VALUES (
				(SELECT name FROM (VALUES ('Gearboxes ' || random_number), ('Servo motors ' || random_number), ('LiDAR sensors ' || random_number)) AS names(name) ORDER BY random() LIMIT 1),   
				(SELECT category FROM (VALUES ('Mechanical transmissions'), ('Sensors'), ('Drives and motors')) AS categories(category) ORDER BY random() LIMIT 1)	
			);
	
			inserted_count := inserted_count + 1;
		EXCEPTION
            WHEN unique_violation THEN
                CONTINUE;
        END;
    END LOOP;

    RAISE NOTICE 'Total inserted addresses: %', inserted_count;
END;$$;


ALTER PROCEDURE public.random_component_category(IN counts integer) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 16585)
-- Name: random_components(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.random_components(IN counts integer)
    LANGUAGE plpgsql
    AS $$DECLARE
    name_random TEXT;
    random_weight DOUBLE PRECISION;
    device_id_random INTEGER;
    random_number INTEGER;
    inserted_count INTEGER := 0;
    existing_count INTEGER;
    last_id INTEGER;
    name_list TEXT[];
    device_id_list INTEGER[];
BEGIN
    SELECT ARRAY(SELECT name FROM component_category) INTO name_list;
    SELECT ARRAY(SELECT device_id FROM device) INTO device_id_list;
    
    SELECT COUNT(*) INTO existing_count FROM components;
    SELECT COALESCE(MAX(component_id), 0) INTO last_id FROM components;

    WHILE inserted_count < counts LOOP
        random_weight := random() * 100;
        name_random := name_list[FLOOR(random() * array_length(name_list, 1) + 1)::INTEGER];
        device_id_random := device_id_list[FLOOR(random() * array_length(device_id_list, 1) + 1)::INTEGER];

        BEGIN
            INSERT INTO components (name, weight, device_id)
            VALUES (name_random, random_weight, device_id_random);

            inserted_count := inserted_count + 1;
        EXCEPTION
            WHEN foreign_key_violation THEN
                RAISE NOTICE 'Error: there is no such key';
                EXIT;
            WHEN unique_violation THEN
                CONTINUE;
        END;
    END LOOP;

    RAISE NOTICE 'Total inserted addresses: %', inserted_count;
END;$$;


ALTER PROCEDURE public.random_components(IN counts integer) OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 16576)
-- Name: random_device(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.random_device(IN counts integer)
    LANGUAGE plpgsql
    AS $$DECLARE
	random_date DATE;
	factory_id_random INTEGER;
	factory_ids INTEGER[];
    random_number INTEGER;
    inserted_count INTEGER := 0;
	existing_count INTEGER;
	last_id INTEGER;
BEGIN
	SELECT ARRAY(SELECT factory_id FROM factory) INTO factory_ids;
	
	SELECT COUNT(*) INTO existing_count FROM device;
	SELECT COALESCE(MAX(device_id), 0) INTO last_id FROM device;
    WHILE inserted_count < counts LOOP
		random_date := (timestamp '2024-01-01 00:00:00' + random() * (timestamp '2024-12-30 00:00:00' - timestamp '2024-01-01 00:00:00'))::DATE;
        factory_id_random := factory_ids[FLOOR(random() * array_length(factory_ids, 1) + 1)::INTEGER];
		BEGIN
			INSERT INTO device (name, task, operating_system, factory_id, date)
			VALUES (
				(SELECT name FROM (VALUES ('robot KR QUANTEC'), ('robot IRB 6700'), ('robot Spot')) AS names(name) ORDER BY random() LIMIT 1),
				(SELECT task FROM (VALUES ('universal production processes such as welding, packaging, component handling, and precision material processing.'), 
				('heavy lifting operations, welding, material handling, automation of assembly processes'), 
				('inspection of hard-to-reach or dangerous places, data collection, and assistance in rescue operations')) AS tasks(task) ORDER BY random() LIMIT 1),
				(SELECT operating_system FROM (VALUES ('KUKA System Software'), ('RobotWare'), ('Spot SDK')) AS operating_systems(operating_system) ORDER BY random() LIMIT 1),
				 factory_id_random,
				 random_date
			);
	
			inserted_count := inserted_count + 1;
		EXCEPTION
			WHEN foreign_key_violation THEN
				RAISE NOTICE 'Error: there is no such key';
                EXIT;
            WHEN unique_violation THEN
                CONTINUE;
        END;
    END LOOP;

    RAISE NOTICE 'Total inserted addresses: %', inserted_count;
END;$$;


ALTER PROCEDURE public.random_device(IN counts integer) OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 16569)
-- Name: random_factory(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.random_factory(IN counts integer)
    LANGUAGE plpgsql
    AS $$DECLARE
    address_prefix TEXT := 'Address ';
    new_address TEXT;
    random_number INTEGER;
    inserted_count INTEGER := 0;
	existing_count INTEGER;
	last_id INTEGER;
BEGIN
	SELECT COUNT(*) INTO existing_count FROM factory;
	SELECT COALESCE(MAX(factory_id), 0) INTO last_id FROM factory;
    WHILE inserted_count < counts LOOP
        random_number := FLOOR(RANDOM() * (counts + existing_count + 1 - last_id)) + last_id;
        new_address := address_prefix || random_number;

        BEGIN
            INSERT INTO factory (name, specialization, address)
            VALUES (
                (SELECT name FROM (VALUES ('KUKA Robotics'), ('ABB Robotics'), ('Boston Dynamics')) AS names(name) ORDER BY random() LIMIT 1),
                (SELECT specialization FROM (VALUES ('industrial robots for assembly and processing'), ('industrial robots for automation of production processes'), ('mobile robots with advanced maneuvering capabilities')) AS specializations(specialization) ORDER BY random() LIMIT 1),
                new_address
            );

            inserted_count := inserted_count + 1;
        EXCEPTION
            WHEN unique_violation THEN
                CONTINUE;
        END;
    END LOOP;

    RAISE NOTICE 'Total inserted addresses: %', inserted_count;
END;$$;


ALTER PROCEDURE public.random_factory(IN counts integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 16424)
-- Name: buy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.buy (
    component_id integer NOT NULL,
    factory_id integer NOT NULL,
    date timestamp with time zone NOT NULL,
    price double precision NOT NULL
);


ALTER TABLE public.buy OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16490)
-- Name: component_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.component_category (
    name character varying(20) NOT NULL,
    category character varying(30) NOT NULL
);


ALTER TABLE public.component_category OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16414)
-- Name: components; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.components (
    component_id integer NOT NULL,
    name character varying(20) NOT NULL,
    weight double precision NOT NULL,
    device_id integer
);


ALTER TABLE public.components OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16528)
-- Name: components_component_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.components ALTER COLUMN component_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.components_component_id_seq
    START WITH 4
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 216 (class 1259 OID 16404)
-- Name: device; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device (
    device_id integer NOT NULL,
    name character varying(20) NOT NULL,
    task character varying(200) NOT NULL,
    operating_system character varying(20) NOT NULL,
    factory_id integer NOT NULL,
    date timestamp with time zone
);


ALTER TABLE public.device OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16527)
-- Name: device_device_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.device ALTER COLUMN device_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.device_device_id_seq
    START WITH 4
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 215 (class 1259 OID 16399)
-- Name: factory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factory (
    factory_id integer NOT NULL,
    name character varying(30) NOT NULL,
    specialization character varying(60) NOT NULL,
    address character varying(70) NOT NULL
);


ALTER TABLE public.factory OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16572)
-- Name: factory_factory_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.factory ALTER COLUMN factory_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.factory_factory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 221 (class 1259 OID 16517)
-- Name: tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks (
    id integer NOT NULL,
    title text NOT NULL,
    description text
);


ALTER TABLE public.tasks OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16516)
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tasks_id_seq OWNER TO postgres;

--
-- TOC entry 4895 (class 0 OID 0)
-- Dependencies: 220
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- TOC entry 4717 (class 2604 OID 16520)
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- TOC entry 4883 (class 0 OID 16424)
-- Dependencies: 218
-- Data for Name: buy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.buy (component_id, factory_id, date, price) FROM stdin;
15	2	2024-02-11 00:00:00+02	5.149344889730088
11	7	2024-09-26 00:00:00+03	4.752422659967726
9	7	2024-09-28 00:00:00+03	2.240347892380379
27	3	2024-11-25 00:00:00+02	4.561986169006589
20	9	2024-10-23 00:00:00+03	7.3557978676773335
21	9	2024-07-07 00:00:00+03	1.6593951768553716
34	7	2024-09-27 00:00:00+03	1.8772417134627561
6	2	2024-03-10 00:00:00+02	8.161432855231642
16	3	2024-01-12 00:00:00+02	6.664295626261665
23	3	2024-11-18 00:00:00+02	7.154703701521246
38	4	2024-03-21 00:00:00+02	3.01743938448068
30	4	2024-09-09 00:00:00+03	5.715429404979428
36	7	2024-05-06 00:00:00+03	5.709303127650898
8	9	2024-03-27 00:00:00+02	3.040026783899874
26	2	2024-04-30 00:00:00+03	0.34110359719111694
32	2	2024-09-13 00:00:00+03	5.881132890640788
24	7	2024-04-19 00:00:00+03	1.3446470159561685
39	2	2024-02-25 00:00:00+02	7.07541705539249
25	4	2024-06-02 00:00:00+03	5.383370149641764
12	4	2024-02-28 00:00:00+02	5.845568607196792
\.


--
-- TOC entry 4884 (class 0 OID 16490)
-- Dependencies: 219
-- Data for Name: component_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.component_category (name, category) FROM stdin;
Gearboxes 36	Sensors
LiDAR sensors 13	Mechanical transmissions
Servo motors 31	Sensors
Gearboxes 23	Drives and motors
Servo motors 17	Drives and motors
Servo motors 13	Sensors
Servo motors 6	Mechanical transmissions
LiDAR sensors 5	Mechanical transmissions
Servo motors 29	Sensors
Servo motors 28	Sensors
Servo motors 35	Drives and motors
LiDAR sensors 21	Sensors
Gearboxes 33	Drives and motors
Gearboxes 37	Mechanical transmissions
Gearboxes 1	Drives and motors
LiDAR sensors 20	Sensors
Servo motors 7	Drives and motors
Gearboxes 13	Mechanical transmissions
Gearboxes 4	Drives and motors
Servo motors 4	Sensors
Servo motors 12	Mechanical transmissions
LiDAR sensors 1	Drives and motors
Gearboxes 11	Mechanical transmissions
LiDAR sensors 35	Drives and motors
Gearboxes 35	Mechanical transmissions
Gearboxes 0	Sensors
Gearboxes 19	Sensors
Servo motors 21	Mechanical transmissions
Gearboxes 15	Drives and motors
Gearboxes 20	Drives and motors
LiDAR sensors 38	Drives and motors
Servo motors 26	Drives and motors
Servo motors 3	Drives and motors
Servo motors 37	Mechanical transmissions
Gearboxes 29	Sensors
Servo motors 19	Mechanical transmissions
Gearboxes 24	Sensors
LiDAR sensors 33	Drives and motors
LiDAR sensors 19	Drives and motors
LiDAR sensors 4	Mechanical transmissions
\.


--
-- TOC entry 4882 (class 0 OID 16414)
-- Dependencies: 217
-- Data for Name: components; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.components (component_id, name, weight, device_id) FROM stdin;
1	Gearboxes 4	26.282619478281788	14
2	LiDAR sensors 19	57.22434798626159	8
3	Servo motors 6	52.65451403174644	4
4	Gearboxes 13	2.2473964204559493	12
5	Servo motors 13	79.58189671800322	15
6	Servo motors 4	82.77932745648965	7
7	Gearboxes 0	9.470759609425583	11
8	Gearboxes 23	68.21092176072656	11
9	Gearboxes 20	56.700017234123564	7
10	LiDAR sensors 33	57.26867449758113	6
11	LiDAR sensors 33	12.934703645113643	18
12	Servo motors 21	76.92561807249871	20
13	Gearboxes 33	81.69408729915588	7
14	LiDAR sensors 35	29.448314175817814	7
15	Gearboxes 4	68.02051996441472	6
16	Servo motors 37	68.74588439564675	12
17	LiDAR sensors 5	49.01882601452034	14
18	Gearboxes 0	32.22109173084211	5
19	Servo motors 37	69.15555958979918	11
20	Servo motors 21	57.807711502235115	12
21	Gearboxes 19	36.28483570184346	10
22	LiDAR sensors 21	27.522025021167806	15
23	Gearboxes 35	15.153535885318203	4
24	Servo motors 7	7.323572358622643	6
25	Gearboxes 35	43.47233825179229	12
26	Gearboxes 37	12.243447156749188	22
27	Servo motors 6	11.499996554522829	21
28	Servo motors 12	57.064539680243676	4
29	Servo motors 31	95.97941246880694	5
30	LiDAR sensors 35	23.62873223016331	8
31	Gearboxes 36	6.033034064057685	18
32	Servo motors 6	77.78019295120681	21
33	LiDAR sensors 21	21.032190309787026	3
34	Gearboxes 24	59.13185415273796	11
35	Gearboxes 20	49.95358986723375	8
36	Gearboxes 13	34.03987390426546	18
37	LiDAR sensors 13	90.4601717122207	19
38	Servo motors 35	73.10983640323843	9
39	Gearboxes 0	92.04982139283314	22
40	Servo motors 13	5.74647785257949	22
\.


--
-- TOC entry 4881 (class 0 OID 16404)
-- Dependencies: 216
-- Data for Name: device; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device (device_id, name, task, operating_system, factory_id, date) FROM stdin;
3	robot Spot	universal production processes such as welding, packaging, component handling, and precision material processing.	RobotWare	9	2024-04-11 00:00:00+03
4	robot Spot	universal production processes such as welding, packaging, component handling, and precision material processing.	Spot SDK	2	2024-07-02 00:00:00+03
5	robot Spot	heavy lifting operations, welding, material handling, automation of assembly processes	RobotWare	9	2024-03-05 00:00:00+02
6	robot Spot	inspection of hard-to-reach or dangerous places, data collection, and assistance in rescue operations	RobotWare	7	2024-06-28 00:00:00+03
7	robot IRB 6700	universal production processes such as welding, packaging, component handling, and precision material processing.	KUKA System Software	2	2024-10-03 00:00:00+03
8	robot KR QUANTEC	inspection of hard-to-reach or dangerous places, data collection, and assistance in rescue operations	RobotWare	7	2024-06-14 00:00:00+03
9	robot Spot	universal production processes such as welding, packaging, component handling, and precision material processing.	Spot SDK	4	2024-05-30 00:00:00+03
10	robot IRB 6700	heavy lifting operations, welding, material handling, automation of assembly processes	Spot SDK	2	2024-08-03 00:00:00+03
11	robot IRB 6700	universal production processes such as welding, packaging, component handling, and precision material processing.	KUKA System Software	3	2024-01-01 00:00:00+02
12	robot IRB 6700	heavy lifting operations, welding, material handling, automation of assembly processes	KUKA System Software	2	2024-03-02 00:00:00+02
13	robot Spot	heavy lifting operations, welding, material handling, automation of assembly processes	KUKA System Software	2	2024-07-18 00:00:00+03
14	robot Spot	universal production processes such as welding, packaging, component handling, and precision material processing.	KUKA System Software	7	2024-08-28 00:00:00+03
15	robot Spot	universal production processes such as welding, packaging, component handling, and precision material processing.	RobotWare	4	2024-05-25 00:00:00+03
16	robot IRB 6700	heavy lifting operations, welding, material handling, automation of assembly processes	RobotWare	7	2024-08-13 00:00:00+03
17	robot IRB 6700	universal production processes such as welding, packaging, component handling, and precision material processing.	KUKA System Software	2	2024-05-02 00:00:00+03
18	robot Spot	heavy lifting operations, welding, material handling, automation of assembly processes	KUKA System Software	3	2024-02-02 00:00:00+02
19	robot IRB 6700	universal production processes such as welding, packaging, component handling, and precision material processing.	RobotWare	7	2024-05-09 00:00:00+03
20	robot KR QUANTEC	universal production processes such as welding, packaging, component handling, and precision material processing.	RobotWare	2	2024-01-06 00:00:00+02
21	robot Spot	inspection of hard-to-reach or dangerous places, data collection, and assistance in rescue operations	RobotWare	4	2024-05-07 00:00:00+03
22	robot IRB 6700	inspection of hard-to-reach or dangerous places, data collection, and assistance in rescue operations	RobotWare	3	2024-01-20 00:00:00+02
\.


--
-- TOC entry 4880 (class 0 OID 16399)
-- Dependencies: 215
-- Data for Name: factory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.factory (factory_id, name, specialization, address) FROM stdin;
3	Boston Dynamics	industrial robots for assembly and processing	Address 3
4	ABB Robotics	industrial robots for automation of production processes	Address 2
7	ABB Robotics	industrial robots for automation of production processes	Address 4
9	ABB Robotics	mobile robots with advanced maneuvering capabilities	Address 1
2	newname	newspec	newadres
\.


--
-- TOC entry 4886 (class 0 OID 16517)
-- Dependencies: 221
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks (id, title, description) FROM stdin;
\.


--
-- TOC entry 4896 (class 0 OID 0)
-- Dependencies: 223
-- Name: components_component_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.components_component_id_seq', 40, true);


--
-- TOC entry 4897 (class 0 OID 0)
-- Dependencies: 222
-- Name: device_device_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.device_device_id_seq', 22, true);


--
-- TOC entry 4898 (class 0 OID 0)
-- Dependencies: 224
-- Name: factory_factory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.factory_factory_id_seq', 9, true);


--
-- TOC entry 4899 (class 0 OID 0)
-- Dependencies: 220
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_id_seq', 1, false);


--
-- TOC entry 4719 (class 2606 OID 16515)
-- Name: factory address; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factory
    ADD CONSTRAINT address UNIQUE (address);


--
-- TOC entry 4727 (class 2606 OID 16474)
-- Name: buy buy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buy
    ADD CONSTRAINT buy_pkey PRIMARY KEY (component_id);


--
-- TOC entry 4729 (class 2606 OID 16498)
-- Name: component_category component_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_category
    ADD CONSTRAINT component_category_pkey PRIMARY KEY (name);


--
-- TOC entry 4725 (class 2606 OID 16418)
-- Name: components components_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.components
    ADD CONSTRAINT components_pkey PRIMARY KEY (component_id);


--
-- TOC entry 4723 (class 2606 OID 16408)
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (device_id);


--
-- TOC entry 4721 (class 2606 OID 16403)
-- Name: factory factory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_pkey PRIMARY KEY (factory_id);


--
-- TOC entry 4731 (class 2606 OID 16524)
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- TOC entry 4735 (class 2606 OID 16552)
-- Name: buy buy_component; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buy
    ADD CONSTRAINT buy_component FOREIGN KEY (component_id) REFERENCES public.components(component_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 4736 (class 2606 OID 16557)
-- Name: buy buy_factory; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buy
    ADD CONSTRAINT buy_factory FOREIGN KEY (factory_id) REFERENCES public.factory(factory_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 4733 (class 2606 OID 16599)
-- Name: components components_componet_category; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.components
    ADD CONSTRAINT components_componet_category FOREIGN KEY (name) REFERENCES public.component_category(name) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 4734 (class 2606 OID 16542)
-- Name: components components_device; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.components
    ADD CONSTRAINT components_device FOREIGN KEY (device_id) REFERENCES public.device(device_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 4732 (class 2606 OID 16537)
-- Name: device factory_device; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT factory_device FOREIGN KEY (factory_id) REFERENCES public.factory(factory_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


-- Completed on 2024-11-26 14:07:04

--
-- PostgreSQL database dump complete
--

