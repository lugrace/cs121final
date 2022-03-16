"""
-- [Grace Lu - glu@caltech.edu]
-- [Jae Yoon Kim - jaeyoonk@caltech.edu]
"""
import sys  # to print error messages to sys.stderr.write(str
import mysql.connector
# To get error codes from the connector, useful for user-friendly
# error-handling
import mysql.connector.errorcode as errorcode
import time
import getpass

# Debugging flag to print errors when debugging that shouldn't be visible
# to an actual client. Set to False when done testing.
DEBUG = False


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
            sys.stderr.write('Incorrect username or password when connecting to DB.')
        elif err.errno == errorcode.ER_BAD_DB_ERROR and DEBUG:
            sys.stderr.write('Database does not exist.')
        elif DEBUG:
            sys.stderr.write(str(err))
        else:
            sys.stderr.write('An error occurred, please contact the administrator.')
        sys.exit(1)

# ----------------------------------------------------------------------
# Functions for Command-Line Options/Query Execution
# ----------------------------------------------------------------------

def new_user():
    """
    Administrators are able to create a new user a
    """
    username = input('New User\'s username: ')
    password = input('New User\'s password: ')
    cursor = conn.cursor()
    sql = 'CALL sp_add_user(\'%s\',\'%s\')' % (username, password)
    try:
        cursor.execute(sql)
    except mysql.connector.Error as err:
        # Since they are administrators, they can see the error message 
        sys.stderr.write(str(err))
        sys.exit(1)
    admin_status = input('Are they going to be an admin? (y) or (n)').lower()
    match admin_status:
        case 'y':
            make_admin(username)
        case 'n':
            print('OK. Complete.')
        case _:
            print('Invalid Option. Please try again ')


def make_admin(username = None):
    """
    Administrators are able to give a certain username administrator
    privileges.
    """
    if username is None:
        username = input('User\'s username: ')
    cursor = conn.cursor()
    sql = 'CALL sp_give_admin(\'%s\')' % (username,)
    try:
        cursor.execute(sql)
        print(f'Completed! {username} is an administrator!')
        print('With great power, comes great responsibility. Use it wisely.')
    except mysql.connector.Error as err:
        # Since they are administrators, they can see the error message 
        sys.stderr.write(str(err))
        sys.exit(1)
    

def check_admin():
    """
    Used to check a user's privileges.
    """
    username = input('User\'s username: ')
    cursor = conn.cursor()
    sql = 'SELECT check_admin(\'%s\')' % (username,)
    is_admin = int(get_first_element(sql))
    if is_admin:
        print(f'{username} is an Administrator.')
    else:
        print(f'{username} is not an Administrator.')


def run_top_ten():
    """
    Used to run the move_top_ten procedure
        The procedure takes the top ten most purchased product and place them
        in a brand new aisle to make one aisle very attractive. The store
        manager can put this aisle in the back so that customers have to 
        look for their favorite items by browsing through other aisles to maybe
        discover items that they don't normally purchase.
    """

    cursor = conn.cursor()
    sql = 'CALL move_top_ten();'
    try:
        cursor.execute(sql)
        print('Move Completed.')
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr.write(str(err))
            sys.exit(1)
        else:
            sys.stderr.write('An error occurred, please contact the administrator.')


def popular_per_day():
    """
    Most popular products ordered for each day of the week 
        based on the number of purchases for that product
    """
    print('\n' + '-'*80 + '\n\n')

    cursor = conn.cursor()
    sql = '''
    WITH product_orders AS (
        SELECT product_name, order_day_of_week, COUNT(*) AS num_purchases
        FROM orders NATURAL JOIN products
        GROUP BY product_name, order_day_of_week
        ORDER BY order_day_of_week, num_purchases DESC
    ),
    popular_purchases_per_day AS (
        SELECT order_day_of_week, MAX(num_purchases) AS num_purchases
        FROM product_orders 
        GROUP BY order_day_of_week
    )
    SELECT order_day_of_week, product_name 
    FROM popular_purchases_per_day NATURAL JOIN product_orders;
    '''
    try:
        cursor.execute(sql)
        rows = cursor.fetchall()
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr.write(str(err))
            sys.exit(1)
        else:
            sys.stderr.write('An error occurred, please contact the administrator.')

    date_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    result = [[x, []] for x in date_names]
    for data in rows:
        result[data[0]][1].append(data[1])

    print('Most popular items by day of week:')
    for day in result:
        pretty = ', '.join(day[1])
        print(f'{day[0]}:  \t{pretty}')

def avg_items_in_cart():
    """
    Average number of items in a user's cart
    """
    print('\n' + '-'*80 + '\n\n')

    cursor = conn.cursor()
    sql = '''
    WITH items_in_order AS (
        SELECT user_id, order_id, COUNT(*) AS num_items_in_cart
        FROM orders NATURAL JOIN user_orders
        GROUP BY user_id, order_id
    )
    SELECT user_id, AVG(num_items_in_cart) AS avg_cart_size
    FROM items_in_order
    GROUP BY user_id;
    '''
    try:
        cursor.execute(sql)
        rows = cursor.fetchall()
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr.write(str(err))
            sys.exit(1)
        else:
            sys.stderr.write('An error occurred, please contact the administrator.')
    print('Average items in a user\'s cart:')
    max_id_len = max([len(str(x[0])) for x in rows]) + 2
    print(' User ID' + ' ' * (max_id_len - 6) + '|' + '  # of items')
    print('--' + '-' * max_id_len + '+' + '-'*20)
    for row in rows:
        left = str(row[0]).ljust(max_id_len, ' ')
        print(f'  {left}|  {str(row[1])}')
    print('+-' + '-' * max_id_len + '+' + '-'*20)


def num_returning_customers():
    """
    Number of returning customers, so basically customers
        that have placed more than one order
    """
    print('\n' + '-'*80 + '\n\n')

    cursor = conn.cursor()
    sql = '''
    SELECT user_id, COUNT(order_id) AS num_orders_per_user 
    FROM (SELECT DISTINCT user_id, order_id
        FROM orders NATURAL JOIN user_orders) t1
    GROUP BY user_id, order_id
    HAVING COUNT(order_id) > 1;
    '''
    try:
        cursor.execute(sql)
        row = cursor.fetchone()
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr.write(str(err))
            sys.exit(1)
        else:
            sys.stderr.write('An error occurred, please contact the administrator.')
    print(f'Number of Returning customers: {row}')

def clean(rows, space = 2):
    clean_rows = [[str(x).strip() for x in row] for row in rows]
    lengths = [[len(x) for x in row] for row in clean_rows]
    maxs = list(map(max, zip(*lengths)))

    clean_rows = [[x.ljust(space + maxs[i]) for i, x in enumerate(row)] for row in clean_rows]
    return (clean_rows, maxs)

def pop_aisle():
    """
    Most popular aisles and number of visits for that aisle
    """

    print('\n' + '-'*80 + '\n\n')

    cursor = conn.cursor()
    sql = '''
    WITH aisle_info AS (
        SELECT product_id, product_name, aisle_id, aisle
        FROM orders NATURAL JOIN products NATURAL JOIN aisles
    )
    SELECT aisle_id, aisle, COUNT(*) AS num_aisle_visits 
    FROM aisle_info
    GROUP BY aisle_id, aisle
    ORDER BY num_aisle_visits DESC;
    '''
    try:
        cursor.execute(sql)
        rows = cursor.fetchall()
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr.write(str(err))
            sys.exit(1)
        else:
            sys.stderr.write('An error occurred, please contact the administrator.')
    print('Most popular aisles:')
    clean_rows, maxs = clean(rows)
    a_length, b_length, c_length = [x + 2 for x in maxs]
    print(
        '  ID' + ' '*(a_length - 2) + 
        '|  Aisle Name' + ' '*(b_length - 10) + 
        '|  Number of visits')
    print('-' * 69)
    for row in clean_rows:
        a, b, c = row[0], row[1], row[2]
        print(f'  {a}|  {b}|  {c}')

def pop_item_per_aisle():
    """
    Most popular item for each aisle
    """

    print('\n' + '-'*80 + '\n\n')

    cursor = conn.cursor()
    sql = '''
    WITH aisle_info AS (
        SELECT product_id, product_name, aisle_id, aisle
        FROM orders NATURAL JOIN products NATURAL JOIN aisles
    ),
    popular_item_aisle_ct AS (
        SELECT aisle_id, aisle, product_id, product_name, COUNT(*) AS product_ct 
        FROM aisle_info 
        GROUP BY aisle_id, product_id
    ),
    popular_item_per_aisle AS (
        SELECT aisle_id, aisle, product_id, product_name, most_pop_item_ct
        FROM (SELECT aisle_id, MAX(product_ct) AS most_pop_item_ct
        FROM popular_item_aisle_ct
        GROUP BY aisle_id) t1 NATURAL JOIN popular_item_aisle_ct
    )
    SELECT * 
    FROM popular_item_per_aisle
    ORDER BY aisle_id ASC;
    '''
    try:
        cursor.execute(sql)
        rows = cursor.fetchall()
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr.write(str(err))
            sys.exit(1)
        else:
            sys.stderr.write('An error occurred, please contact the administrator.')
    print('Most popular item per aisle:')
    clean_rows, maxs = clean(rows)
    print('HEADER')
    print('-'*70)
    for row in clean_rows:
        print('  ' + '|  '.join(row))


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
            sys.stderr.write(str(err))
            sys.exit(1)
        else:
            sys.stderr.write('An error occurred. Please contact the administrator.')

def login():
    """
    Logs in the user with their appropriate permissions
    """
    print('+----------------------------------------------------------------+')
    username = input('\tEnter your username: ')
    password = getpass.getpass('\tEnter your password: ')
    print('+----------------------------------------------------------------+')
    
    response = int(get_first_element('SELECT authenticate(\'%s\', \'%s\');' % (username, password, )))
    if response:
        is_admin = int(get_first_element('SELECT check_admin(\'%s\')' % (username, )))
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
    while True:
        print('What would you like to do? \n\n')
        print('  (ch)\t- Check if a user has administrator privileges.')
        print('  (tt)\t- Move top ten popular products to new aisle')
        print('  (pp)\t- Find the most popular products for each day of the week')
        print('  (avg)\t- Find average number of items in a user cart')
        print('  (re)\t- Number of returning customers')
        print('  (po)\t- Most popular aisles')
        print('  (pa)\t- Most popular item per aisle')
        print('  (q)\t- quit')
        print()
        ans = input('Enter an option: ').lower()
        match ans:
            case 'q':
                quit_ui()
            case 'ch':
                check_admin()
            case 'tt':
                run_top_ten()
            case 'pp':
                popular_per_day()
            case 'avg':
                avg_items_in_cart()
            case 're':
                num_returning_customers()
            case 'po':
                pop_aisle()
            case 'pa':
                pop_item_per_aisle()
            case _:
                print(f'\'{ans}\' is an invalid option. Goodbye.')
                quit_ui()


def show_admin_options():
    """
    Displays options specific for admins, such as adding new data <x>,
    modifying <x> based on a given id, removing <x>, etc.
    """

    while True:
        print('+----------------------------------------------------------------+')
        print('What would you like to do?\n\n')
        print('  (nu)\t- Add a new user')
        print('  (ma)\t- Make a user an administrator')
        print('  (ch)\t- Check if a user has administrator privileges.')
        print('  (tt)\t- Move top ten popular products to new aisle')
        print('  (pp)\t- Find the most popular products for each day of the week')
        print('  (avg)\t- Find average number of items in a user cart')
        print('  (re)\t- Number of returning customers')
        print('  (po)\t- Most popular aisles')
        print('  (pa)\t- Most popular item per aisle')
        print('  (q)\t- quit')
        print()
        ans = input('Enter an option: ').lower()

        match ans:
            case 'q':
                quit_ui()
            case 'nu':
                new_user()
            case 'ma':
                make_admin()
            case 'ch':
                check_admin()
            case 'tt':
                run_top_ten()
            case 'pp':
                popular_per_day()
            case 'avg':
                avg_items_in_cart()
            case 're':
                num_returning_customers()
            case 'po':
                pop_aisle()
            case 'pa':
                pop_item_per_aisle()
            case _:
                print(f'\'{ans}\' is an invalid option. Goodbye.')
                quit_ui()

def quit_ui():
    """
    Quits the program, printing a good bye message to the user.
    """
    print('Goodbye!')
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
