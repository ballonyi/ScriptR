create or replace and compile java source named scriptr$$ as
import java.util.*;
import java.sql.*;
import java.io.*;
import oracle.jdbc.*;
import java.text.SimpleDateFormat;
import java.lang.Math.*;
import java.util.Base64;
import javax.xml.bind.DatatypeConverter;

public class Scriptr{


    /**
    * converts a byte array to a hexadecimal string
    **/
    private static final char[] HEX_ARRAY = "0123456789ABCDEF".toCharArray();
    public static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for (int j = 0; j < bytes.length; j++) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = HEX_ARRAY[v >>> 4];
            hexChars[j * 2 + 1] = HEX_ARRAY[v & 0x0F];
        }
        return new String(hexChars);
    }  
    
            
    /**
    * Clob content longer than 4000 chars split to chunks stitched together in the insert statement as 
    * to_clob(q'~... 4000 chars ...~')||to_clob(q'~... 4000 chars ...~')||to_clob(q'~... 4000 chars ...~') etc
    **/
    public static void clobSplit( TableColumn col, String content, char quotingChar ){
        int SIZE = 4000;
        System.out.println("clobSplit: length="+content.length());         
        String nl = content.length()>200 ? "\n" : "";
        for (int start = 0; start < content.length(); start += SIZE) {  
          String chunk = content.substring(start, Math.min(content.length(), start + SIZE));  
          System.out.println("start: "+start);         
          col.getValues().add("q'"+quotingChar+chunk+quotingChar+"'");                            
        }     
        System.out.println("size: "+col.getValues().size());         
    }
         
    public static void blobSplit( TableColumn col, byte[] content ){
        int SIZE = 2000;
        String result = null;        
        //System.out.println("blobSplit: length="+content.length); 
        String nl = content.length>200 ? "\n" : "";        
        
        for (int start = 0; start < content.length; start += SIZE) {
          int end = start+Math.min(content.length-start,SIZE);
          //System.out.println("from="+start+", to="+end);  
          byte[] chunk = Arrays.copyOfRange(content, start, end );                                                        
          //System.out.println("chunk="+chunk.length);            
          col.getValues().add( "'"+bytesToHex(chunk)+"'");          
          //System.out.println(bytesToHex(chunk));            
        } 
        //System.out.println("blobSplit: vége "+col.getValues().size()); 
    }    
    
    /**
    * returns the values(...) part of then given resultset row in format as need to be placed in the insert statement
    **/
    public static void processRow(int size, ResultSet rs, TableRow columns, char quotingChar) throws SQLException{    
        String value=null;
        String v=null;
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy.MM.dd HH:mm:ss");        
        
        columns.clearValues();
        
        for (TableColumn col : columns) {
                    
            if( !col.isExcluded() ){                                        
                switch (col.getDataType()) {
                case "NUMBER":
                    v = String.valueOf(rs.getDouble(col.getColumnName()));                        
                    if( !rs.wasNull() ){
                        value = (col.getDataScale()==null || col.getDataScale()>0) ? v :  String.valueOf(rs.getInt(col.getColumnName()));
                    } else {
                        value ="null";
                    } 
                    col.getValues().add(value);                            
                    
                    break;
                    
                case "VARCHAR2":
                case "CHAR":
                     v = rs.getString(col.getColumnName());                   
                     value = rs.wasNull() ? "null" : "q'"+quotingChar+v+quotingChar+"'";                          
                     col.getValues().add(value);        
                     col.getValues().add(value);                            
                     break;
                     
                case "DATE": 
                    Timestamp ts = rs.getTimestamp(col.getColumnName());
                    value = rs.wasNull() ? "null" : "to_date('"+sdf.format(ts)+"','yyyy.mm.dd hh24:mi:ss')";                     
                    col.getValues().add(value);                            
                    break;  
                                      
                case "CLOB":
                    java.sql.Clob c = rs.getClob(col.getColumnName());                  
                    if( !rs.wasNull() ){
                        clobSplit(col, c.getSubString(1, (int)c.length()), quotingChar);                           
                    } else {
                        col.getValues().add("null");                            
                    }                     
                    break; 
                    
                case "BLOB":
                   java.sql.Blob b = rs.getBlob(col.getColumnName());                  
                   if( !rs.wasNull() ){
                        blobSplit( col, b.getBytes(1, (int)b.length()));                           
                    } else {
                        col.getValues().add("null");                            
                    }                     
                    break; 
                                                                      
                default:
                    col.getValues().add("null");                            
                } 
                                        
            } else {
                col.getValues().add("null");                            
            } 
                              
        }  // for columns             
        
        //return cols;
    }
    
    public static oracle.sql.CLOB getInsertScript( String owner, 
                                                   String tableName, 
                                                   String excludedCols, 
                                                   String where, 
                                                   String quoting ) throws SQLException{
    
        char quotingChar = quoting==null ? '~' : quoting.charAt(0);
        TableRow currentRow = new TableRow();
        currentRow.init( owner, tableName, excludedCols );
        Connection cn = DriverManager.getConnection("jdbc:default:connection:");
        oracle.sql.CLOB clob = oracle.sql.CLOB.createTemporary(cn, false, oracle.sql.CLOB.DURATION_SESSION);                     
                    
        String sql = String.format("select * from %s.%s %s", owner,tableName, ((where==null) ? "" : " where "+where));               
        System.out.println(sql); 
           
        System.out.println("-----------------------------------------------------------------------------------------");                 
        System.out.println(sql);                 
         
        String script = null; 
        String cmd = null;   
        try( Statement stmt = cn.createStatement(); ResultSet rs = stmt.executeQuery(sql);){
            while (rs.next()) {

                processRow(currentRow.size(), rs, currentRow, quotingChar);

                String ins = String.format("\n\tinsert into %s(%s)\n\tvalues(%s);",
                                               tableName,
                                               currentRow.joinedFieldList(),
                                               currentRow.joinedValueList());

                if( currentRow.getNumOfFilledLobColumns(currentRow)>0 ){
                    cmd = "\ndeclare";
                    // declare variables for clob and blob columns
                    for (TableColumn col : currentRow) {
                        if( col.isColumnLobAndFilled() ){
                            cmd += String.format("\n\t%s;",col.getVariableDefinition() );                            
                        }
                    } 
                    cmd += "\nbegin";
                    System.out.println(cmd);                 
                    // set clob and blob variables                    
                    for (TableColumn col : currentRow) {
                        if( col.isColumnLobAndFilled() ) {
                            cmd += "\n\tdbms_lob.createtemporary("+col.getVariableName()+", TRUE);";  
                            
                            for(int j=0; j<col.getValues().size(); ++j){
                               String chunk = col.getValues().get(j);
                               if( col.getDataType().equals("CLOB") ){
                                    String oper = (j==0) ? "" : col.getVariableName()+"||";
                                    cmd += "\n\t"+col.getVariableName()+":= "+oper+"to_clob("+chunk+");"; 
                               }
                               else if( col.getDataType().equals("BLOB") ){                            
                                    cmd += "\n\tdbms_lob.append("+col.getVariableName()+", hextoraw("+chunk+"));"; 
                               }                                 
                            }                                                               
                        }
                    }
                    cmd = cmd+ins;                
                    cmd += "\nend;\n/";
                } else {
                    cmd = ins;
                }

                script = (script==null) ? cmd : script + "\n"+ cmd;
                
                                                                   
            } 
        } 
        
        System.out.println(script); 
        
        if(script!=null){
            clob.setString(1, script);                
        }           
        return clob;
    }


}
/
