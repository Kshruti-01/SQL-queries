/*STORED PROCEDURES
Create a procedure InsertOrderDetails that takes OrderID, ProductID, UnitPrice,
Quantiy, Discount as input parameters and inserts that order information in the
Order Details table. After each order inserted, check the @@rowcount value to
make sure that order was inserted properly. If for any reason the order was not
inserted, print the message: Failed to place the order. Please try again. Also your
procedure should have these functionalities
Make the UnitPrice and Discount parameters optional
If no UnitPrice is given, then use the UnitPrice value from the product table.
If no Discount is given, then use a discount of 0.
Adjust the quantity in stock (UnitsInStock) for the product by subtracting the quantity
sold from inventory.
However, if there is not enough of a product in stock, then abort the stored procedure
without making any changes to the database.
Print a message if the quantity in stock of a product drops below its Reorder Level as a
result of the update.*/
CREATE PROCEDURE InsertOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @OrderQty SMALLINT,
    @Discount DECIMAL(5,2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StockQty INT;
    DECLARE @ReorderPoint INT;
    DECLARE @DefaultPrice MONEY;

    -- Get current stock and reorder level
    SELECT @StockQty = p.SafetyStockLevel,  -- AdventureWorks uses SafetyStockLevel
           @ReorderPoint = p.ReorderPoint,
           @DefaultPrice = p.ListPrice
    FROM Production.Product p
    WHERE p.ProductID = @ProductID;

    -- If UnitPrice not given, use ListPrice from Product
    IF @UnitPrice IS NULL
        SET @UnitPrice = @DefaultPrice;

    -- Check for stock availability
    IF @StockQty < @OrderQty
    BEGIN
        PRINT 'Not enough stock available. Order aborted.';
        RETURN;
    END

    -- Insert into SalesOrderDetail
    INSERT INTO Sales.SalesOrderDetail
    (
        SalesOrderID,
        ProductID,
        OrderQty,
        UnitPrice,
        UnitPriceDiscount,
        rowguid,
        ModifiedDate
    )
    VALUES
    (
        @OrderID,
        @ProductID,
        @OrderQty,
        @UnitPrice,
        @Discount,
        NEWID(),
        GETDATE()
    );

    -- Check if insert was successful
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Failed to place the order. Please try again.';
        RETURN;
    END

    -- Update Product stock (simulate by subtracting from SafetyStockLevel)
    UPDATE Production.Product
    SET SafetyStockLevel = SafetyStockLevel - @OrderQty
    WHERE ProductID = @ProductID;

    -- Check if new stock level is below ReorderPoint
    IF (@StockQty - @OrderQty) < @ReorderPoint
    BEGIN
        PRINT 'Warning: Product stock has dropped below the reorder level.';
    END

    PRINT 'Order inserted successfully.';
END;

/*Create a procedure UpdateOrderDetails that takes OrderID, ProductID, UnitPrice,
Quantity, and discount, and updates these values for that ProductID in that Order.
All the parameters except the OrderID and ProductID should be optional so that if
the user wants to only update Quantity s/he should be able to do so without
providing the rest of the values. You need to also make sure that if any of the values
are being passed in as NULL, then you want to retain the original value instead of
overwriting it with NULL. To accomplish this, look for the ISNULL() function in
google or sql server books online. Adjust the UnitsInStock value in products table
accordingly.*/
-- Drop the existing procedure if it exists

-- Drop InsertOrderDetails if it exists
IF OBJECT_ID('dbo.InsertOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE dbo.InsertOrderDetails;
GO
-- Drop UpdateOrderDetails if it exists
IF OBJECT_ID('dbo.UpdateOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE dbo.UpdateOrderDetails;
GO

-- Now CREATE UpdateOrderDetails as usual
CREATE PROCEDURE dbo.UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity SMALLINT = NULL,
    @Discount MONEY = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldQty SMALLINT;
    DECLARE @OldPrice MONEY;
    DECLARE @OldDiscount DECIMAL(5,2);
    DECLARE @CurrentStock INT;
    DECLARE @QtyDiff INT;
    DECLARE @NewQty SMALLINT;

    SELECT @OldQty = OrderQty,
           @OldPrice = UnitPrice,
           @OldDiscount = UnitPriceDiscount
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    IF @OldQty IS NULL
    BEGIN
        PRINT 'Order detail not found.';
        RETURN;
    END

    SET @NewQty = ISNULL(@Quantity, @OldQty);
    SET @UnitPrice = ISNULL(@UnitPrice, @OldPrice);
    SET @Discount = ISNULL(@Discount, @OldDiscount);

    SELECT @CurrentStock = SafetyStockLevel
    FROM Production.Product
    WHERE ProductID = @ProductID;

    SET @QtyDiff = @OldQty - @NewQty;

    UPDATE Sales.SalesOrderDetail
    SET OrderQty = @NewQty,
        UnitPrice = @UnitPrice,
        UnitPriceDiscount = @Discount,
        ModifiedDate = GETDATE()
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    UPDATE Production.Product
    SET SafetyStockLevel = SafetyStockLevel + @QtyDiff
    WHERE ProductID = @ProductID;

    PRINT 'Order detail updated successfully.';
END;
GO

/*Create a procedure GetOrderDetails that takes OrderID as input parameter and
returns all the records for that OrderID. If no records are found in Order Details
table, then it should print the line: "The OrderID XXXX does not exits", where
XXX should be the OrderID entered by user and the procedure should RETURN
the value 1.*/
CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if any records exist for the given OrderID
    IF NOT EXISTS (
        SELECT 1
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID
    )
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN 1;
    END

    -- If records exist, return them
    SELECT *
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID;
END;
GO
/*Create a procedure DeleteOrderDetails that takes OrderID and ProductID and
deletes that from Order Details table. Your procedure should validate parameters.
It should return an error code (-1) and print a message if the parameters are
invalid. Parameters are valid if the given order ID appears in the table and if the
given product ID appears in that order.*/
CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: Validate Order and Product
    IF NOT EXISTS (
        SELECT 1 FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID
          AND ProductID = @ProductID
    )
    BEGIN
        PRINT 'Error: Invalid parameters. Either the OrderID does not exist or the ProductID is not part of the order.';
        RETURN -1;
    END

    -- Step 2: Perform the deletion
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID
      AND ProductID = @ProductID;

    PRINT 'Order detail deleted successfully.';
END;
GO

--FUNCTONS
/*Create a function that takes an input parameter type datetime and returns the date
in the format MM/DD/YYYY. For example if I pass in '2006-11-21 23:34:05.920',
the output of the functions should be 11/21/2006*/
CREATE FUNCTION dbo.FormatDate_MMDDYYYY
(
    @InputDate DATETIME
)
RETURNS VARCHAR(10)
AS
BEGIN
    -- Format as MM/DD/YYYY
    RETURN CONVERT(VARCHAR(10), @InputDate, 101);  -- Style 101 = mm/dd/yyyy
END;
GO

/*Create a function that takes an input parameter type datetime and returns the date
in the format YYYYMMDD*/
CREATE FUNCTION dbo.FormatDate_YYYYMMDD
(
    @InputDate DATETIME
)
RETURNS VARCHAR(8)
AS
BEGIN
    -- Format as YYYYMMDD
    RETURN CONVERT(VARCHAR(8), @InputDate, 112);  -- Style 112 = YYYYMMDD
END;
GO

--VIEWS
/*Create a view vwCustomerOrders which returns CompanyName,OrderID,OrderDate,
ProductID,ProductName, Quantity, UnitPrice,Quantity * od.UnitPrice*/
CREATE VIEW vwCustomerOrders AS
SELECT 
    s.Name AS CompanyName,
    oh.SalesOrderID AS OrderID,
    oh.OrderDate,
    p.ProductID,
    p.Name AS ProductName,
    od.OrderQty AS Quantity,
    od.UnitPrice,
    od.OrderQty * od.UnitPrice AS Total
FROM Sales.SalesOrderHeader oh
JOIN Sales.Customer c ON oh.CustomerID = c.CustomerID
JOIN Sales.SalesOrderDetail od ON oh.SalesOrderID = od.SalesOrderID
JOIN Production.Product p ON od.ProductID = p.ProductID
JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID;
GO

/*Create a copy of the above view and modify it so that it only returns the above information
for orders that were placed yesterday*/
CREATE VIEW vwCustomerOrders_Yesterday AS
SELECT 
    s.Name AS CompanyName,
    oh.SalesOrderID AS OrderID,
    oh.OrderDate,
    p.ProductID,
    p.Name AS ProductName,
    od.OrderQty AS Quantity,
    od.UnitPrice,
    od.OrderQty * od.UnitPrice AS Total
FROM Sales.SalesOrderHeader oh
JOIN Sales.Customer c ON oh.CustomerID = c.CustomerID
JOIN Sales.SalesOrderDetail od ON oh.SalesOrderID = od.SalesOrderID
JOIN Production.Product p ON od.ProductID = p.ProductID
JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
WHERE CAST(oh.OrderDate AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
GO

/*Use a CREATE VIEW statement to create a view called MyProducts. Your view should
contain the ProductID, ProductName, QuantityPerUnit and UnitPrice columns from the
Products table. It should also contain the CompanyName column from the Suppliers table
and the CategoryName column from the Categories table. Your view should only contain
products that are not discontinued.*/
CREATE VIEW MyProducts AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber AS QuantityPerUnit,    -- Best match for QuantityPerUnit
    p.ListPrice AS UnitPrice,
    v.Name AS CompanyName,
    ps.Name AS CategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Purchasing.ProductVendor pv 
    ON p.ProductID = pv.ProductID
INNER JOIN Purchasing.Vendor v 
    ON pv.BusinessEntityID = v.BusinessEntityID
WHERE p.DiscontinuedDate IS NULL;         -- Include only active products
GO


--TRIGGERS
/*If someone cancels an order in northwind database, then you want to delete that
order from the Orders table. But you will not be able to delete that Order before
deleting the records from Order Details table for that particular order due to
referential integrity constraints. Create an Instead of Delete trigger on Orders table
so that if some one tries to delete an Order that trigger gets fired and that trigger
should first delete everything in order details table and then delete that order from
the Orders table*/
CREATE TRIGGER trg_InsteadOfDelete_SalesOrder
ON Sales.SalesOrderHeader
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: Delete related order details
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID IN (SELECT SalesOrderID FROM DELETED);

    -- Step 2: Delete from SalesOrderHeader
    DELETE FROM Sales.SalesOrderHeader
    WHERE SalesOrderID IN (SELECT SalesOrderID FROM DELETED);

    PRINT 'Order and related order details deleted successfully.';
END;
GO
/*When an order is placed for X units of product Y, we must first check the Products
table to ensure that there is sufficient stock to fill the order. This trigger will operate
on the Order Details table. If sufficient stock exists, then fill the order and
decrement X units from the UnitsInStock column in Products. If insufficient stock
exists, then refuse the order (i.e. do not insert it) and notify the user that the order
could not be filled because of insufficient stock.*/
CREATE TRIGGER trg_CheckStockBeforeInsert
ON Sales.SalesOrderDetail
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID INT,
            @OrderQty INT,
            @CurrentStock INT;

    -- Assume only one row is inserted at a time for simplicity
    SELECT 
        @ProductID = ProductID,
        @OrderQty = OrderQty
    FROM INSERTED;

    -- Get current stock from ProductInventory (using default LocationID = 1)
    SELECT @CurrentStock = Quantity
    FROM Production.ProductInventory
    WHERE ProductID = @ProductID AND LocationID = 1;

    -- Check if enough stock is available
    IF @CurrentStock IS NULL OR @CurrentStock < @OrderQty
    BEGIN
        PRINT 'Error: Insufficient stock. Order cannot be placed.';
        RETURN;
    END

    -- Insert the new order detail
    INSERT INTO Sales.SalesOrderDetail (
        SalesOrderID,
        ProductID,
        OrderQty,
        UnitPrice,
        UnitPriceDiscount,
        rowguid,
        ModifiedDate
    )
    SELECT 
        SalesOrderID,
        ProductID,
        OrderQty,
        UnitPrice,
        UnitPriceDiscount,
        NEWID(),
        GETDATE()
    FROM INSERTED;

    -- Update inventory
    UPDATE Production.ProductInventory
    SET Quantity = Quantity - @OrderQty
    WHERE ProductID = @ProductID AND LocationID = 1;

    PRINT 'Order placed successfully. Inventory updated.';
END;
GO





