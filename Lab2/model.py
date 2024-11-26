import psycopg
import time
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, DOUBLE_PRECISION
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text


# Базовий клас для моделей
Base = declarative_base()


# Модель таблиці User
class Factory(Base):
    __tablename__ = "factory"

    factory_id = Column(Integer, primary_key=True, nullable=False)
    name = Column(String(30), nullable=False)
    specialization = Column(String(60), nullable=False)
    address = Column(String(70), unique=True, nullable=False)

class Device(Base):
    __tablename__ = "device"

    device_id = Column(Integer, primary_key=True, nullable=False)
    name = Column(String(20), nullable=False)
    task = Column(String(200), nullable=False)
    operating_system = Column(String(20), nullable=False)
    factory_id = Column(Integer, ForeignKey('factory.factory_id'), nullable=False)
    date = Column(DateTime, nullable=False)
    
class Components(Base):
    __tablename__ = "components"

    component_id = Column(Integer, primary_key=True, nullable=False)
    name = Column(String(20), ForeignKey('component_category.name'), nullable=False)
    weight = Column(DOUBLE_PRECISION, nullable=False)
    device_id = Column(Integer,  ForeignKey('device.device_id'))
    
class Component_Category(Base):
    __tablename__ = "component_category"

    name = Column(String(20), primary_key=True, nullable=False)
    category = Column(String(30), nullable=False)
    
class Buy(Base):
    __tablename__ = "buy"

    component_id = Column(Integer, ForeignKey('components.component_id'), primary_key=True, nullable=False)
    factory_id = Column(Integer, ForeignKey('factory.factory_id'), nullable=False)
    date = Column(DateTime, nullable=False)
    price = Column(DOUBLE_PRECISION, nullable=False)

class Model:
    def __init__(self):
        
        self.DATABASE_URL = "postgresql+psycopg://postgres:0000@localhost:5432/lab1"
        
        self.engine = create_engine(self.DATABASE_URL, echo=True)
        
        Base.metadata.create_all(self.engine)

        self.Session = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        

    def get_attributes(self, table):
        return Base.metadata.tables[table.lower()].columns.keys()

        
    def add_row(self, attributes, attributes_name, table):
        session = self.Session()
        
        table = Base.metadata.tables[table.lower()]

        new_row = {}
        for column_name, column_value in zip(attributes_name, attributes):
            if column_name in table.columns:
                new_row[column_name] = column_value

        session.execute(table.insert().values(new_row))
        session.commit()
        
    def get_DeviceOfFactory(self, FK):
        session = self.Session()

        start_time = time.time()

        query = text("""
            SELECT f.factory_id, f.name, f.address, d.name, COUNT(*) as count
            FROM device d
            JOIN factory f ON d.factory_id = f.factory_id
            WHERE f.factory_id = :fk
            GROUP BY f.factory_id, d.name
            ORDER BY f.factory_id ASC
        """)
        
        result = session.execute(query, {'fk': FK}).fetchall()

        end_time = time.time()
        duration = end_time - start_time
        
        column_names = [col[0] for col in session.execute(query, {'fk': FK}).cursor.description]
        
        return result, column_names, duration * 1000

    def get_ComponentsOfDevice(self, FK):
        session = self.Session()

        start_time = time.time()

        query = text("""
            SELECT d.device_id, d.name, c.name, AVG(c.weight) as avg_weight
            FROM device d
            JOIN components c ON d.device_id = c.device_id
            WHERE d.device_id = :fk
            GROUP BY d.device_id, c.name
            ORDER BY d.device_id ASC
        """)

        result = session.execute(query, {'fk': FK}).fetchall()

        end_time = time.time()
        duration = end_time - start_time

        column_names = [col[0] for col in session.execute(query, {'fk': FK}).cursor.description]

        return result, column_names, duration * 1000

    def get_BuyOfComponents(self, first_date, second_date, FK):
        session = self.Session()

        start_time = time.time()

        query = text("""
            SELECT f.factory_id, f.name, c.component_id, c.name, b.date, b.price
            FROM buy b
            JOIN factory f ON b.factory_id = f.factory_id
            JOIN components c ON b.component_id = c.component_id
            WHERE b.date BETWEEN :first_date AND :second_date
            AND f.factory_id = :fk
            ORDER BY f.factory_id ASC
        """)
    
        result = session.execute(query, {'first_date': first_date, 'second_date': second_date, 'fk': FK}).fetchall()

        end_time = time.time()
        duration = end_time - start_time

        column_names = [desc[0] for desc in session.execute(query, {'first_date': first_date, 'second_date': second_date, 'fk': FK}).cursor.description]

        return result, column_names, duration * 1000

    
    def get_all_rows(self, table):
        session = self.Session()
        return session.query(Base.metadata.tables[table.lower()]).all()

    def update_row(self, row_id, PK, attributes, attributes_name, table):
        session = self.Session()

        table = Base.metadata.tables[table.lower()]

        update_values = {}
        for column_name, column_value in zip(attributes_name, attributes):
            if column_name in table.columns:
                update_values[column_name] = column_value

        condition = getattr(table.c, PK) == row_id
        session.execute(table.update().where(condition).values(update_values))

        session.commit()
          

    def delete_row(self, row_id, PK, table):
        session = self.Session()

        table = Base.metadata.tables[table.lower()]
        condition = getattr(table.c, PK) == row_id
        session.execute(table.delete().where(condition))

        session.commit()
        
    def reset_identity(self, table, session):
        query = text(f"""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = :table 
            AND is_identity = 'YES'
            ORDER BY ordinal_position 
            LIMIT 1;
        """)
        result = session.execute(query, {'table': table.lower()}).fetchone()

        if result:
            identity_column = result[0]
            
            alter_query = text(f"ALTER TABLE {table} ALTER COLUMN {identity_column} RESTART WITH 1")
            session.execute(alter_query)
    
    def delete_table(self, table):
        session = self.Session()
       
        query = text(f'TRUNCATE TABLE {table.lower()} CASCADE')
        session.execute(query)
        self.reset_identity(table, session)

        session.commit()
        
    def random_table(self, counts, table):
        session = self.Session()

        query = text(f"CALL random_{table.lower()}(:counts)")
        session.execute(query, {'counts': counts})

        session.commit()

    def query_rollback(self):
        session = self.Session()
        session.rollback()