package sample;
import java.sql.*;
import java.util.*;

public class Assignment {
	public static final String address = "jdbc:mysql://mysql.wmi.amu.edu.pl/";
	public String base;
	public String user;
	public String pass;
	/*s444460_tin*/
	
	public Assignment(Scanner sc) {
		System.out.println("Username:");
		this.user=sc.nextLine();
		System.out.println("Password:");
		this.pass=sc.nextLine();
		System.out.println("Database:");
		this.base=sc.nextLine();
		
	}
	public static void main(String[]args) {
		Scanner sc = new Scanner(System.in);
		Assignment kek = new Assignment(sc);
		kek.connect(sc);
	}
	public Connection connect(Scanner sc) {
		Connection conn = null;
		try {
			conn = DriverManager.getConnection(address+base,user,pass);
			System.out.println("Enter a query");
			String query = sc.nextLine();
			PreparedStatement pre = conn.prepareStatement(query);
			ResultSet tab = pre.executeQuery();
			int count = tab.getMetaData().getColumnCount();
			for(int i=1;i<count;i++) {
				System.out.print(tab.getMetaData().getColumnName(i) + " ");
			}
			System.out.println(tab.getMetaData().getColumnName(count));
			System.out.println("----");
			while(tab.next()) {
				for(int i=1;i<count;i++) {
					System.out.print(tab.getString(i) + " ");
				}
				System.out.println(tab.getString(count));
			}
		}
		catch (SQLException e) {
			System.out.println(e.getMessage());
		}
		return conn;
	}
}
