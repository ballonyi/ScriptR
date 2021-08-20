create or replace package scriptr$ AUTHID CURRENT_USER is

    /*
                                                S c r i p t - R
    
                                             Author: Gyula Ballonyi
                                              Created : 2021.05.15
                                              
            Returns a CLOB value containing a list of insert statements to reproduce the contents of the specified table.
            Handled datatypes: CHAR, VARCHAR, NUMBER, DATE, CLOB, BLOB (others types scripted as NULL content).
            Comma separated list of columns to be excluded can be specified.
            Text values scripted with literal quoting, the default quoting character is tilde char.
            
    */
    function getInsertScript(p_owner        varchar2 default user,
                             p_tableName    varchar2,
                             p_excludedCols varchar2 default null,
                             p_where        varchar2 default null,
                             p_quotingChar  varchar2 default '~') return clob;

end;
/
create or replace package body scriptr$ is

    function j$getInsertScript(p_owner varchar2, 
                               p_tableName varchar2, 
                               p_excludedCols varchar2, 
                               p_where varchar2, 
                               p_quotingChar varchar2) return clob as
        language java name 'Scriptr.getInsertScript(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String) return oracle.sql.CLOB';

    function getInsertScript(p_owner        varchar2 default user,
                             p_tableName    varchar2,
                             p_excludedCols varchar2 default null,
                             p_where        varchar2 default null,
                             p_quotingChar  varchar2 default '~') return clob as
    begin
        return j$getInsertScript(p_owner        => p_owner,
                                 p_tableName    => p_tableName,
                                 p_excludedCols => p_excludedCols,
                                 p_where        => p_where,
                                 p_quotingChar  => p_quotingChar);
    end;

end;
/
