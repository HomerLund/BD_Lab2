from tabulate import tabulate
class View:
    def show_table(self, rows, attributes_name, table):
        print(table + ":") 
        table = tabulate(rows, attributes_name, tablefmt="grid")
        print(table)

    def get_table_input(self, attributes_name, table):
        attributes = []  
   
        for attribute in attributes_name:
            attributes.append(input("Enter " + table + " " + attribute + ": "))

        return attributes
    
    def get_DeviceOfFactory(self):
        return int(input("Enter factory_id: "))
    
    def get_ComponentsOfDevice(self):
        return int(input("Enter device_id: "))
    
    def get_BuyOfComponents(self):
        return str(input("Enter first date: ")), str(input("Enter second date: "))
    
    def get_row_id(self, table):
        return int(input("Enter " + table + " ID: "))
    
    def enter_choice(self, choice):
        while (True):
            try:
                return int(input(choice))
            except Exception as e:     
                print(f"Error: {e}")
        
    def confirm_delete_table(self):
        return int(input("Enter 1 to delete the table or 0 to cancel: "))
    
    def random_table(self):
        return int(input("Enter number of rows: "))
    
    def show_message(self, message):
        print(message)
