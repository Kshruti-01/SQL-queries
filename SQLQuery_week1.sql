/* SQL queries assignment Download  and use adventure works  
1. list of all customers*/
SELECT * FROM Sales.Customer;

--2.List of all cutomers where company name ending in N */
SELECT c.CustomerID, s.Name AS CompanyName
FROM Sales.Customer c
JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
WHERE s.Name LIKE '%N';

--3.List of all customer who live in berlin or London 
SELECT DISTINCT c.CustomerID, a.City
FROM Sales.Customer c
JOIN Person.BusinessEntityAddress bea ON c.PersonID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
WHERE a.City IN ('Berlin', 'London');


--4.List of all customers who live in UK or USA 
SELECT DISTINCT c.CustomerID, a.City, cr.Name AS Country
FROM Sales.Customer c
JOIN Person.BusinessEntityAddress b ON c.PersonID = b.BusinessEntityID
JOIN Person.Address a ON b.AddressID = a.AddressID
JOIN Person.StateProvince s ON a.StateProvinceID = s.StateProvinceID
JOIN Person.CountryRegion cr ON s.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name IN ('United Kingdom', 'United States');


--5.List of all products sorted by product name
SELECT ProductID, Name, ProductNumber, StandardCost, ListPrice
FROM Production.Product
ORDER BY Name ASC;

--6. List of all products where products name starts with A
SELECT ProductID, Name, ProductNumber, ListPrice
FROM Production.Product
WHERE Name LIKE 'A%';


--7. List of all customers who have placed an order
SELECT DISTINCT c.CustomerID, p.FirstName, p.LastName, c.StoreID, c.TerritoryID
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
WHERE soh.CustomerID IS NOT NULL;

--8.List of customer who live in Londonand bought chai
SELECT DISTINCT c.CustomerID, p.FirstName, p.LastName, a.City, soh.SalesOrderID
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
JOIN Person.BusinessEntityAddress bea ON c.PersonID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
WHERE a.City = 'London'
  AND pr.Name = 'Chai';

--9.List of customers who never place an order
SELECT c.CustomerID, p.FirstName, p.LastName
FROM Sales.Customer c
LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
WHERE soh.CustomerID IS NULL;


--10.List of customers who orderd tofu
SELECT DISTINCT
    c.CustomerID,
    ISNULL(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
WHERE pr.Name = 'Tofu';


--11.Details of first order of the system
SELECT
    sod.SalesOrderID,
    pr.Name AS ProductName,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM Sales.SalesOrderDetail sod
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
WHERE sod.SalesOrderID = (
    SELECT TOP 1 SalesOrderID
    FROM Sales.SalesOrderHeader
    ORDER BY OrderDate ASC
);

--12.Find the details of most expensive order date
SELECT TOP 1
    soh.SalesOrderID,
    soh.OrderDate,
    c.CustomerID,
    ISNULL(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    soh.TotalDue
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
ORDER BY soh.TotalDue DESC;

--13.For each order get the orderID and Average quantity of items in that order
SELECT 
    SalesOrderID,
    AVG(CAST(OrderQty AS FLOAT)) AS AvgQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

--14.For each order get the OrderID, minimum quantity, and maximum quantity for that order
SELECT 
    SalesOrderID,
    MIN(OrderQty) AS MinQuantity,
    MAX(OrderQty) AS MaxQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

--15.Get a list of all managers and total number of employees who report to them
SELECT 
    mgr.BusinessEntityID AS ManagerID,
    p.FirstName + ' ' + p.LastName AS ManagerName,
    COUNT(e.BusinessEntityID) AS NumberOfReports
FROM HumanResources.Employee e
JOIN HumanResources.Employee mgr ON e.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
JOIN Person.Person p ON mgr.BusinessEntityID = p.BusinessEntityID
GROUP BY mgr.BusinessEntityID, p.FirstName, p.LastName
ORDER BY NumberOfReports DESC;



--16.Get the orderID and the total quantity for each order that has a total quantity of greater than 300
SELECT 
    SalesOrderID,
    SUM(OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(OrderQty) > 300;

--17.List of all orders placed on or after 1996/12/31
SELECT 
    SalesOrderID,
    OrderDate,
    CustomerID,
    TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '1996-12-31'
ORDER BY OrderDate;

--18.List of all orders shipped to Canada
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    c.CustomerID,
    soh.TotalDue,
    a.City,
    a.StateProvinceID,
    sp.Name AS StateProvince,
    co.Name AS Country
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion co ON sp.CountryRegionCode = co.CountryRegionCode
WHERE co.Name = 'Canada'
ORDER BY soh.OrderDate;

--19.List of all orders  with order total>200
SELECT 
    SalesOrderID,
    OrderDate,
    CustomerID,
    TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue > 200
ORDER BY TotalDue DESC;

--20.List of countries and sales made in each country
SELECT 
    cr.Name AS Country,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalSales DESC;

--21.List of customers ContactName and number of order they placed
SELECT 
    c.CustomerID,
    ISNULL(p.FirstName + ' ' + p.LastName, s.Name) AS ContactName,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, p.FirstName, p.LastName, s.Name
ORDER BY NumberOfOrders DESC;

--22.List of customer contactnames who have placed more than 3 orders
SELECT 
    ISNULL(p.FirstName + ' ' + p.LastName, s.Name) AS ContactName,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName, s.Name
HAVING COUNT(soh.SalesOrderID) > 3
ORDER BY NumberOfOrders DESC;

--23.List of discontinued products which were ordered between 1/11997 and 1/1/1998
SELECT DISTINCT 
    p.ProductID,
    p.Name AS ProductName,
    p.SellEndDate,
    soh.OrderDate
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE 
    p.SellEndDate IS NOT NULL AND
    soh.OrderDate BETWEEN '1997-01-01' AND '1998-01-01'
ORDER BY p.Name;

--24.List of employee firstname, Lastname, superviser FirstName, LastName
SELECT 
    emp.BusinessEntityID AS EmployeeID,
    pe.FirstName AS EmployeeFirstName,
    pe.LastName AS EmployeeLastName,
    mgr.BusinessEntityID AS SupervisorID,
    pm.FirstName AS SupervisorFirstName,
    pm.LastName AS SupervisorLastName
FROM HumanResources.Employee emp
JOIN Person.Person pe ON emp.BusinessEntityID = pe.BusinessEntityID
JOIN HumanResources.Employee mgr ON emp.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
JOIN Person.Person pm ON mgr.BusinessEntityID = pm.BusinessEntityID
ORDER BY SupervisorLastName, EmployeeLastName;


--25.list of employeeID and total sale conducted by employee
SELECT 
    soh.SalesPersonID AS EmployeeID,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
WHERE soh.SalesPersonID IS NOT NULL
GROUP BY soh.SalesPersonID
ORDER BY TotalSales DESC;

--26.List of employees whose first name contains a character A
SELECT 
    e.BusinessEntityID AS EmployeeID,
    p.FirstName,
    p.LastName
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE p.FirstName LIKE '%A%' OR p.FirstName LIKE '%a%'
ORDER BY p.FirstName;

--27. List of managers who have more than four people reporting to them
SELECT 
    mgr.BusinessEntityID AS ManagerID,
    p.FirstName + ' ' + p.LastName AS ManagerName,
    COUNT(emp.BusinessEntityID) AS NumberOfReports
FROM HumanResources.Employee emp
JOIN HumanResources.Employee mgr 
    ON emp.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
JOIN Person.Person p ON mgr.BusinessEntityID = p.BusinessEntityID
GROUP BY mgr.BusinessEntityID, p.FirstName, p.LastName
HAVING COUNT(emp.BusinessEntityID) > 4
ORDER BY NumberOfReports DESC;

--28.List of Orders and ProductName
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    pr.Name AS ProductName
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
ORDER BY soh.SalesOrderID;

--29.List of Orders place by the best customer
SELECT TOP 1
    CustomerID,
    SUM(TotalDue) AS TotalSpent
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY TotalSpent DESC;

--30.List of orders placed by customer who do not have a Fax Number
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.CustomerID,
    ISNULL(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
LEFT JOIN Person.PersonPhone pp ON c.PersonID = pp.BusinessEntityID AND pp.PhoneNumberTypeID = (
    SELECT PhoneNumberTypeID FROM Person.PhoneNumberType WHERE Name = 'Fax'
)
WHERE pp.PhoneNumber IS NULL
ORDER BY soh.OrderDate;

--31. List of postal code where the product tofu shipped
SELECT DISTINCT
    a.PostalCode
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
WHERE p.Name = 'Tofu';

--32.List of product name that were shipped to France
SELECT DISTINCT
    p.Name AS ProductName
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
WHERE sp.CountryRegionCode = 'France';

--33.List of ProductName and categories for the supplier Speciality Biscuits, Ltd
SELECT 
    p.Name AS ProductName, 
    psc.Name AS CategoryName
FROM Production.Product p
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
JOIN Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
WHERE v.Name = 'Speciality Biscuits, Ltd'
ORDER BY p.Name;

--34.List of Products that were never ordered
SELECT p.ProductID, p.Name
FROM Production.Product p
LEFT JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
WHERE sod.ProductID IS NULL
ORDER BY p.Name;

--35.List of products where units in stock is less than 10 and units on order are 0
SELECT DISTINCT p.ProductID, p.Name, pi.Quantity AS UnitsInStock
FROM Production.Product p
JOIN Production.ProductInventory pi ON p.ProductID = pi.ProductID
LEFT JOIN Purchasing.PurchaseOrderDetail pod ON p.ProductID = pod.ProductID AND pod.ReceivedQty < pod.OrderQty
WHERE pi.Quantity < 10 AND pod.PurchaseOrderID IS NULL
ORDER BY p.Name;


--36.List of top 10 countries by sale
SELECT TOP 10
    sp.CountryRegionCode AS Country,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
GROUP BY sp.CountryRegionCode
ORDER BY TotalSales DESC;

--37.Number of orders eavh employee has taken for customers with customerID between A and AO
SELECT
    soh.SalesPersonID AS EmployeeID,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.SalesOrderHeader soh
WHERE soh.CustomerID BETWEEN 1 AND 100
GROUP BY soh.SalesPersonID
ORDER BY NumberOfOrders DESC;

--38.Orderdate of most expensive order
SELECT TOP 1
    OrderDate,
    TotalDue
FROM Sales.SalesOrderHeader
ORDER BY TotalDue DESC;

--39.Product name and total revenue from that product
SELECT 
    p.Name AS ProductName, 
    SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalRevenue DESC;


--40.Supplierid and number of products ordered
SELECT 
    v.BusinessEntityID AS SupplierID,
    COUNT(DISTINCT sod.ProductID) AS NumberOfProductsOrdered
FROM Purchasing.Vendor v
JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
JOIN Sales.SalesOrderDetail sod ON pv.ProductID = sod.ProductID
GROUP BY v.BusinessEntityID
ORDER BY NumberOfProductsOrdered DESC;

--41. top 10 cutomers based on their business
SELECT TOP 10
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    SUM(soh.TotalDue) AS TotalBusiness
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
GROUP BY c.CustomerID, p.FirstName, p.LastName, s.Name
ORDER BY TotalBusiness DESC;

--42. what is the total revenue of the company
SELECT SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader;




