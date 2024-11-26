from pickle import TRUE
from model import Model
from view import View

class Controller:
    def __init__(self):
        self.model = Model()
        self.view = View()
        self.table = ["Factory", "Device", "Components", "Component_category", "Buy"]
        self.attributes_name = []
        self.current_table = "None"
        self.PK = 0
        

    def run(self):
        while True:
            self.model.query_rollback()
            choice = self.show_menu()
            if choice == 1:
                self.add_row()
            elif choice == 2:
                self.view_table()
            elif choice == 3:
                self.update_row()
            elif choice == 4:
                self.delete_row()
            elif choice == 5:
                self.delete_table()
            elif choice == 6:
                self.random_table()
            elif choice == 7:
                break
    
    def show_menu_table(self):
        while(True):
            self.view.show_message("\nMenu:") 
            self.view.show_message("1. Factory")
            self.view.show_message("2. Device")
            self.view.show_message("3. Components")
            self.view.show_message("4. Component_category")
            self.view.show_message("5. Buy")  
            self.view.show_message("6. Search")  
        
            
            number_of_table = self.view.enter_choice("Enter your choice: ") - 1
            if (number_of_table >= 0 and number_of_table < 5):   
                self.current_table = self.table[number_of_table]
                break
            elif (number_of_table != 5):
                self.view.show_message("\nError: not correct choice! Try again!")
            else:
                break
    
    def show_menu_options(self):
        while(True):
            self.view.show_message("\nMenu:")
            self.view.show_message("1. Add " + self.current_table)
            self.view.show_message("2. View " + self.current_table)
            self.view.show_message("3. Update " + self.current_table)
            self.view.show_message("4. Delete row " + self.current_table)
            self.view.show_message("5. Delete table " + self.current_table)
            self.view.show_message("6. Random " + self.current_table)
            self.view.show_message("7. Quit")

            option = self.view.enter_choice("Enter your choice: ")
            if (option >= 1 and option <= 7 ):   
                return option
            else:
                self.view.show_message("\nError: not correct choice! Try again!")
            
    def show_menu_search(self):
        while(True):
            self.view.show_message("\nMenu:")
            self.view.show_message("1. Search the device manufactured by the factory ")
            self.view.show_message("2. Search the components of the device ")
            self.view.show_message("3. Search purchase of components by the plant for a certain period of time ")
            
            option = self.view.enter_choice("Enter your choice: ")
            if (option == 1):
                self.get_DeviceOfFactory()
                break
            elif (option == 2):
                self.get_ComponentsOfDevice()
                break
            elif (option == 3):
                self.get_BuyOfComponents()
                break
            else:
                self.view.show_message("\nError: not correct choice! Try again!")
                
    def show_menu(self):
        try:
            self.current_table = "None"
            self.show_menu_table()
            if (self.current_table != "None"):
                return self.show_menu_options()
            else:
                self.show_menu_search()
                return 0
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()

    def get_DeviceOfFactory(self):
        try:
            FK = self.view.get_DeviceOfFactory()
            rows, self.attributes_name, duration = self.model.get_DeviceOfFactory(FK)
            self.view.show_table(rows, self.attributes_name, "Table")
            self.view.show_message("duration = " + str(duration) + " milliseconds")
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()
            
    def get_ComponentsOfDevice(self):
        try:
            FK = self.view.get_ComponentsOfDevice()
            rows, self.attributes_name, duration = self.model.get_ComponentsOfDevice(FK)
            self.view.show_table(rows, self.attributes_name, "Table")
            self.view.show_message("duration = " + str(duration) + " milliseconds")
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()
            
    def get_BuyOfComponents(self):
        try:
            FK = self.view.get_DeviceOfFactory()
            first_date, second_date = self.view.get_BuyOfComponents()
            rows, self.attributes_name, duration = self.model.get_BuyOfComponents(first_date, second_date, FK)
            self.view.show_table(rows, self.attributes_name, "Table")
            self.view.show_message("duration = " + str(duration) + " milliseconds")
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()
    
    def get_attributes(self):
        self.attributes_name = self.model.get_attributes(self.current_table)
        
        self.PK = self.attributes_name[0]
        return self.attributes_name
        
    def random_table(self):
        try:
            self.attributes_name = self.get_attributes()
            self.model.random_table(self.attributes_name, self.PK, self.current_table)
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()
        
    def add_row(self):
        try:
            self.attributes_name = self.get_attributes()
            if (self.attributes_name[0][-2:] == "id"):
                self.attributes_name = self.attributes_name[1:]
             
            attributes = self.view.get_table_input(self.attributes_name, self.current_table)
            self.model.add_row(attributes, self.attributes_name, self.current_table)
            self.view.show_message(self.current_table + " added successfully!")
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()

    def view_table(self):
        try:
            self.attributes_name = self.get_attributes()
            rows = self.model.get_all_rows(self.current_table)
            self.view.show_table(rows, self.attributes_name, self.current_table)
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()

    def update_row(self):
        try:
            row_id = self.view.get_row_id(self.current_table)
            self.attributes_name = self.get_attributes()
            if (self.attributes_name[0][-2:] == "id"):
                self.attributes_name = self.attributes_name[1:]
            attributes = self.view.get_table_input(self.attributes_name, self.current_table)
            self.model.update_row(row_id, self.PK, attributes, self.attributes_name, self.current_table)
            self.view.show_message("Factory updated successfully!")
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()
            
    def delete_row(self):
        try:
            row_id = self.view.get_row_id(self.current_table)
            self.attributes_name = self.get_attributes()
            self.model.delete_row(row_id, self.PK, self.current_table)
            self.view.show_message(self.current_table + " deleted successfully!")
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()
            
    def delete_table(self):
        try:
            if (self.view.confirm_delete_table()): 
                
                self.model.delete_table(self.current_table)
                self.view.show_message("Delete table successfully")
            else:
                self.view.show_message("Delete table canceled")
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()
            
    def random_table(self):
        try:
            counts = self.view.random_table()
            self.model.random_table(counts, self.current_table)
            self.view.show_message("Random successfully!")
            
        except Exception as e:     
            print(f"Error: {e}")
            self.model.query_rollback()
