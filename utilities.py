
import config as cfg
from sys import exit
from pyodbc import drivers, connect, Error
from utils import email_log, rename_log
from api import get_customer_name
from log import log_info, log_warning, log_error, log_shutdown

def controlled_exit(p_message):
    log_error(p_message) 
    log_shutdown()
    exit()

def connect_db():
    #get list of available SQL Server ODBC drivers for DB connection
    l_drivers = [x for x in drivers() if 'SQL Server' in x]
    #loop through list and exit loop when successful connection.
    l_conn = None
    for i in l_drivers:
        try:
            #connect to local database
            l_conn = connect('Driver='+i+';'
                            'Server='+ cfg.db['server_name'] +';'
                            'Database='+ cfg.db['db_name'] +';'
                            'Trusted_Connection=yes;',
                            autocommit=True)

            break 
        except Exception as e:
            log_warning(str(e)+ '- "' + i + '": Driver used to connect was unsuccessful.. trying other available drivers...')
    #exits program if connection can't be established.
    if not l_conn:
        controlled_exit('FATAL')
    return l_conn
