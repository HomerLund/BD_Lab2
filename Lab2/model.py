import psycopg
import time
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, DOUBLE_PRECISION
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy import text



Base = declarative_base()



class Factory(Base):
    __tablename__ = "factory"

    factory_id = Column(Integer, primary_key=True, nullable=False)
    name = Column(String(30), nullable=False)
    specialization = Column(String(60), nullable=False)
    address = Column(String(70), unique=True, nullable=False)
    
    devices = relationship("Device", back_populates="factory")
    buys = relationship("Buy", back_populates="factory")

class Device(Base):
    __tablename__ = "device"

    device_id = Column(Integer, primary_key=True, nullable=False)
    name = Column(String(20), nullable=False)
    task = Column(String(200), nullable=False)
    operating_system = Column(String(20), nullable=False)
    factory_id = Column(Integer, ForeignKey('factory.factory_id'), nullable=False)
    date = Column(DateTime, nullable=False)
    
    factory = relationship("Factory", back_populates="devices")
    components = relationship("Components", back_populates="device")
    
class Components(Base):
    __tablename__ = "components"

    component_id = Column(Integer, primary_key=True, nullable=False)
    name = Column(String(20), ForeignKey('component_category.name'), nullable=False)
    weight = Column(DOUBLE_PRECISION, nullable=False)
    device_id = Column(Integer,  ForeignKey('device.device_id'))
    
    device = relationship("Device", back_populates="components")
    buys = relationship("Buy", back_populates="component")
    component_category = relationship("Component_Category", back_populates="component")
    
class Component_Category(Base):
    __tablename__ = "component_category"

    name = Column(String(20), primary_key=True, nullable=False)
    category = Column(String(30), nullable=False)
    
    name = Column(String(20), primary_key=True, nullable=False)
    category = Column(String(30), nullable=False)
    
    component = relationship("Components", back_populates="component_category")
    

    
class Buy(Base):
    __tablename__ = "buy"

    component_id = Column(Integer, ForeignKey('components.component_id'), primary_key=True, nullable=False)
    factory_id = Column(Integer, ForeignKey('factory.factory_id'), nullable=False)
    date = Column(DateTime, nullable=False)
    price = Column(DOUBLE_PRECISION, nullable=False)
    
    factory = relationship("Factory", back_populates="buys")
    component = relationship("Components", back_populates="buys")

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

        factory = session.query(Factory).filter_by(factory_id=FK).first()

        end_time = time.time()
        duration = (end_time - start_time) * 1000

        device_counts = {}
        for device in factory.devices:
            device_counts[device.name] = device_counts.get(device.name, 0) + 1

        rows = [
            (factory.factory_id, factory.name, factory.address, device_name, count)
            for device_name, count in device_counts.items()
        ]
        column_names = ["factory_id", "factory_name", "address", "device_name", "count"]
        return rows, column_names, duration

    def get_ComponentsOfDevice(self, FK):
        session = self.Session()

        start_time = time.time()

        device = session.query(Device).filter_by(device_id=FK).first()

        end_time = time.time()
        duration = (end_time - start_time) * 1000

        component_averages = {}
        for component in device.components:
            if component.name not in component_averages:
                component_averages[component.name] = []
            component_averages[component.name].append(component.weight)

        rows = [
            (device.device_id, device.name, component_name, sum(weights) / len(weights))
            for component_name, weights in component_averages.items()
        ]
        column_names = ["device_id", "device_name", "component_name", "avg_weight"]
        return rows, column_names, duration

    def get_BuyOfComponents(self, first_date, second_date, FK):
        session = self.Session()

        start_time = time.time()

        factory = session.query(Factory).filter_by(factory_id=FK).first()

        end_time = time.time()
        duration = (end_time - start_time) * 1000

        rows = [
            (
                factory.factory_id,
                factory.name,
                buy.component.component_id,
                buy.component.name,
                buy.date,
                buy.price,
            )
            for buy in factory.buys
            if first_date <= buy.date <= second_date
        ]
        column_names = [
            "factory_id",
            "factory_name",
            "component_id",
            "component_name",
            "date",
            "price",
        ]
        return rows, column_names, duration

    
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