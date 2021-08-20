# ScriptR
PL/SQL utilitty to generate script containing list of insert statements to reproduce the contents of the specified table.

# Installation
The project can be build using Maven. The result will be appear in target directory as the name of **RibbonMenu-<version>.jar**.
```sh
sqlplus @install.sql
```
## Usage
```sql
create table my_table(
    id       integer,
    code     varchar2(20),
    name     varchar2(100),
    created  date,
    comments clob,
    picture  blob,
    price    number);
  
  
```  
  
