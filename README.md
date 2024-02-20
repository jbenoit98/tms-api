# TMS API
_This independant application programming inferface (API) is not endorsed or supported by the company that owns TMS._

This API is meant to run standalone. It has been proven successful in other forms for more than a dozen museums dating back to 2012 for integrations, application interfaces for data cataloging, and online collections. Please reach out directly to Jonathan (jonathan@amanita.io) for more detail.

### Museum Contributions
This project aims to provide a data IO interface for museums that use TMS - It can be implemented with varying resources within any size museum. Whether it's for sharing object data, planning exhibitions, or even developing teaching resources - It's flexible to fit any requirements. This project relies on the Museum Community for guidance and welcomes all contributions. 

## Technical Details and Roadmap

### Technology Stack
- Language: [Python](https://www.python.org/)
- Web Server: [Tornado](https://www.tornadoweb.org/en/stable/)
- Database: [SQL Server](https://www.microsoft.com/en-us/sql-server)
- Data Validation: [pythonschema](https://python-jsonschema.readthedocs.io/en/stable/)

  
### Security
#### _Trust_
The Tornado web server is configured with Secure Socket Layer (SSL) certificates issued for the specific server machine and web domain used for the API. These certificates force an encrypted handshake to occur between the user connecting to the api and the server to verify that the connection is trusted.
#### _Authenticity_
Only one endpoint will be available without token based authentication - This endpoint accepts user authentication details and returns a JSON Web Token when successfully authenticates. If authentication is successful, a token string will be returned with an expiry timestamp. The token will then need to be used for any endpoint web service calls, such as, querying object data, or inserting media data. The token will expire, but it can be renewed. This is industry standard for REST APIs.

### Database
Currently the database management system that is supported is SQL Server, however, any database management system could be supported given the need. 

### Data Validation
The design is flexible enough to implement organization specific data requirements with low effort by using custom json schema validation. This will ensure that data is validated prior to loading into the database, specific to the organization's data quality standards.


## Install Steps
As we progress in development, these steps will come into focus.


