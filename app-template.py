"""
-- [Grace Lu - glu@caltech.edu]
-- [Jae Yoon Kim - jaeyoonk@caltech.edu]
"""
from fcntl import DN_DELETE
import sys  # to print error messages to sys.stderr
import mysql.connector
# To get error codes from the connector, useful for user-friendly
# error-handling
import mysql.connector.errorcode as errorcode
import time
import getpass

# Debugging flag to print errors when debugging that shouldn't be visible
# to an actual client. Set to False when done testing.
DEBUG = True


# ----------------------------------------------------------------------
# SQL Utility Functions
# ----------------------------------------------------------------------
def get_conn():
    """"
    Returns a connected MySQL connector instance, if connection is successful.
    If unsuccessful, exits.
    """
    try:
        conn = mysql.connector.connect(
          host='localhost',
          user='appadmin',
          # Find port in MAMP or MySQL Workbench GUI or with
          # SHOW VARIABLES WHERE variable_name LIKE 'port';
          port='3306',
          password='adminpw',
          database='final'
        )
        print('Successfully connected.')
        return conn
    except mysql.connector.Error as err:
        # Remember that this is specific to _database_ users, not
        # application users. So is probably irrelevant to a client in your
        # simulated program. Their user information would be in a users table
        # specific to your database.
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR and DEBUG:
            sys.stderr('Incorrect username or password when connecting to DB.')
        elif err.errno == errorcode.ER_BAD_DB_ERROR and DEBUG:
            sys.stderr('Database does not exist.')
        elif DEBUG:
            sys.stderr(err)
        else:
            sys.stderr('An error occurred, please contact the administrator.')
        sys.exit(1)

# ----------------------------------------------------------------------
# Functions for Command-Line Options/Query Execution
# ----------------------------------------------------------------------
def example_query():
    param1 = ''
    cursor = conn.cursor()
    # Remember to pass arguments as a tuple like so to prevent SQL
    # injection.
    sql = 'SELECT col1 FROM table WHERE col2 = \'%s\';' % (param1, )
    try:
        cursor.execute(sql)
        # row = cursor.fetchone()
        rows = cursor.fetchall()
        for row in rows:
            (col1val) = (row) # tuple unpacking!
            # do stuff with row data
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr('An error occurred, give something useful for clients...')


# ----------------------------------------------------------------------
# Functions for Logging Users In
# ----------------------------------------------------------------------

def get_first_element(query):
    """
    Used for getting the first element of the first row of the query
    """
    cursor = conn.cursor()
    try:
        cursor.execute(query)
        response = cursor.fetchone()
        if response and len(response) > 0:
            return response[0]
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr('An error occurred, give something useful for clients...')

def login():
    """
    Logs in the user with their appropriate permissions
    """
    username = input('Enter your username: ')
    password = getpass.getpass('Enter your password: ')
    
    response = int(get_first_element(f'SELECT authenticate(\'{username}\', \'{password}\');'))
    if response:
        is_admin = int(get_first_element(f'SELECT check_admin(\'{username}\')'))
        if is_admin:
            print(f'Welcome Administrator {username}, it is {time.ctime(time.time())}')
            show_admin_options()
        else:
            print(f'Welcome User {username}, it is {time.ctime(time.time())}')
            show_options()
    else:
        print('Login Failed. Goodbye.')
        sys.exit(1)



# ----------------------------------------------------------------------
# Command-Line Functionality
# ----------------------------------------------------------------------
def show_options():
    """
    Displays options users can choose in the application, such as
    viewing <x>, filtering results with a flag (e.g. -s to sort),
    sending a request to do <x>, etc.
    """
    print('What would you like to do? \n\n')
    print('  (x) - something nifty to do')
    print('  (x) - another nifty thing')
    print('  (x) - yet another nifty thing')
    print('  (x) - more nifty things!')
    print('  (q) - quit')
    print()
    ans = input('Enter an option: ').lower()
    match ans:
        case 'q':
            quit_ui()
        case '':
            pass
        case _:
            print(f'\'{ans}\' is an invalid option. Goodbye.')
            quit_ui()


def show_admin_options():
    """
    Displays options specific for admins, such as adding new data <x>,
    modifying <x> based on a given id, removing <x>, etc.
    """
    print('What would you like to do?\n\n')
    print('  (x) - something nifty for admins to do')
    print('  (x) - another nifty thing')
    print('  (x) - yet another nifty thing')
    print('  (x) - more nifty things!')
    print('  (q) - quit')
    print()
    ans = input('Enter an option: ').lower()

    match ans:
        case 'q':
            quit_ui()
        case '':
            pass
        case _:
            print(f'\'{ans}\' is an invalid option. Goodbye.')
            quit_ui()

def quit_ui():
    """
    Quits the program, printing a good bye message to the user.
    """
    print('Good bye!')
    exit()




def main():
    """
    Main function for starting things up.
    """
    login()


if __name__ == '__main__':
    # This conn is a global object that other functinos can access.
    # You'll need to use cursor = conn.cursor() each time you are
    # about to execute a query with cursor.execute(<sqlquery>)
    conn = get_conn()
    main()
