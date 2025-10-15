# Library Management System
Description: Library management is a web application that helps manage library resources including book borrowing and return management, user management better than traditional methods.
## Setting
- JDK 17+
- Apache Tomcat 10
- NetBeans 21
- MySQL in Xampp 8.2
- Import Database: qlthuvien.sql
- Create triggers to update book status and user accounts: TriggerLibrary.txt
## The project folder layout is as follows
<pre>
Web pages
|	-- WEB-INF
|		| -- web.xml
|	-- images
|		| -- default-avatar.png
|		| -- nen2.png
|		| -- reading-book.png
|	-- addBook.jsp
|	-- admin.jsp
|	-- adminBorrowedBook.jsp
|	-- adminDashboard.jsp
|	-- adminReports.jsp
|	-- bookDetails.jsp
|	-- borrowList.jsp
|	-- borrowedBooks.jsp
|	-- createUser.jsp
|	-- editBook.jsp
|	-- index.jsp
|	-- login.jsp
|	-- register.jsp
Source Packages
|	-- Data
|		| -- BookDAO.java
|		| -- Books.java
|		| -- Roles.java
|		| -- UserDAO.java
|		| -- User.java
|	-- Servlet
|		| -- AddUserServlet.java
|		| -- AdminServlet.java
|		| -- ApproveBorrowServlet.java
|		| -- ApproveUserServlet.java
|		| -- BookItemServlet.java
|		| -- BorrowBookServlet.java
|		| -- CancelBorrowServlet.java
|		| -- BDConnection.java
|		| -- DeleteBookServlet.java
|		| -- EmailUtility.java
|		| -- ImageServlet.java
|		| -- LogOutServlet.java
|		| -- LoginServlet.java
|		| -- PasswordHashing.java
|		| -- RegisterServlet.java
|		| -- ReturnBookServlet.java
|		| -- UpdateBookServlet.java
...
</pre>
## Project installation and setup
1. Download Install and unzip it
2. Install Netbeans
3. Because netbeans requires installation with a JDK version greater than 11, please install an additional JDK version at https://www.oracle.com/java/technologies/downloads/ to be able to use Netbean.
4. Start netbeans and add tomcat 10, jdk 21, mysql-connector-j-8.3.0, jakarta.activation-2.0.1.jar, jakarta.activation-api-2.0.1.jar, jakarta.mail-2.0.1.jar
5. Start Xampp and import qlthuvien.sql, create triggers
6. Build and run the project
