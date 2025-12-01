-- Funciones definidas por el usuario 
-- Karin Quispe 
-- 1/12/2025

-- ========== NORTHWIND ========== 
USE Northwind;
GO

-- 1) PedidosPorClienteAnio
 --  Función tabla INLINE: devuelve pedidos de un cliente en un año dado.

IF OBJECT_ID('dbo.PedidosPorClienteAnio','IF') IS NOT NULL
    DROP FUNCTION dbo.PedidosPorClienteAnio;
GO

CREATE OR ALTER FUNCTION dbo.PedidosPorClienteAnio
(
    @CustomerID nchar(5),
    @Anio int
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        O.OrderID,
        O.OrderDate,
        O.EmployeeID,
        O.ShipCountry
    FROM dbo.Orders O
    WHERE O.CustomerID = @CustomerID
      AND YEAR(O.OrderDate) = @Anio
);
GO
-- Ejemplo:
SELECT * FROM dbo.PedidosPorClienteAnio('ALFKI', 1997);


-- 2) TotalVentasEmpleadoPeriodo
-- Función escalar: suma (UnitPrice * Quantity * (1 - Discount)) para pedidos manejados por empleado en un rango de fechas.
-- Devuelve DECIMAL(18,2). Si no hay ventas devuelve 0.
IF OBJECT_ID('dbo.TotalVentasEmpleadoPeriodo','IF') IS NOT NULL
    DROP FUNCTION dbo.TotalVentasEmpleadoPeriodo;
GO

CREATE OR ALTER FUNCTION dbo.TotalVentasEmpleadoPeriodo
(
    @EmployeeID int,
    @FechaInicio date,
    @FechaFin date
)
RETURNS decimal(18,2)
AS
BEGIN
    DECLARE @Total decimal(18,2);

    SELECT @Total = ISNULL(SUM(OD.UnitPrice * OD.Quantity * (1.0 - OD.Discount)), 0)
    FROM dbo.[Order Details] OD
    JOIN dbo.Orders O ON OD.OrderID = O.OrderID
    WHERE O.EmployeeID = @EmployeeID
      AND O.OrderDate >= @FechaInicio
      AND O.OrderDate <= @FechaFin;

    RETURN @Total;
END
GO

-- Ejemplo:
SELECT dbo.TotalVentasEmpleadoPeriodo(5, '1996-01-01', '1997-12-31');



-- 3) ProductosSinStock
--  Función tabla INLINE: devuelve productos cuyo UnitsInStock <= 0 .
IF OBJECT_ID('dbo.ProductosSinStock','IF') IS NOT NULL
    DROP FUNCTION dbo.ProductosSinStock;
GO

CREATE OR ALTER FUNCTION dbo.ProductosSinStock()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        P.ProductID,
        P.ProductName,
        P.UnitsInStock,
        P.UnitsOnOrder
    FROM dbo.Products P
    WHERE ISNULL(P.UnitsInStock,0) <= 0
);
GO

-- Ejemplo:
SELECT * FROM dbo.ProductosSinStock();



-- 4) ClienteTienePedidos
-- Función escalar (validación): devuelve 1 si el cliente tiene al menos un pedido, 0 si no.

IF OBJECT_ID('dbo.ClienteTienePedidos','IF') IS NOT NULL
    DROP FUNCTION dbo.ClienteTienePedidos;
GO

CREATE OR ALTER FUNCTION dbo.ClienteTienePedidos
(
    @CustomerID nchar(5)
)
RETURNS bit
AS
BEGIN
    DECLARE @Tiene bit = 0;
    IF EXISTS (SELECT 1 FROM dbo.Orders O WHERE O.CustomerID = @CustomerID)
       SET @Tiene = 1;
    RETURN @Tiene;
END
GO

-- Ejemplo:
SELECT dbo.ClienteTienePedidos('ALFKI') AS TienePedidos;



-- 5) TopProductosPorCategoria
--  Función tabla MULTI-STATEMENT: devuelve top N productos por cantidad vendida dentro de una categoría.
--  Retorna ProductID, ProductName, TotalCantidadVendida, TotalVentas.
IF OBJECT_ID('dbo.TopProductosPorCategoria','IF') IS NOT NULL
    DROP FUNCTION dbo.TopProductosPorCategoria;
GO

CREATE OR ALTER FUNCTION dbo.TopProductosPorCategoria
(
    @CategoryID int,
    @TopN int
)
RETURNS @Resultado TABLE
(
    ProductID int,
    ProductName nvarchar(40),
    TotalCantidad int,
    TotalVentas decimal(18,2)
)
AS
BEGIN
    INSERT INTO @Resultado (ProductID, ProductName, TotalCantidad, TotalVentas)
    SELECT TOP (@TopN)
        P.ProductID,
        P.ProductName,
        SUM(OD.Quantity) AS TotalCantidad,
        SUM(OD.Quantity * OD.UnitPrice * (1.0 - OD.Discount)) AS TotalVentas
    FROM dbo.[Order Details] OD
    JOIN dbo.Products P ON OD.ProductID = P.ProductID
    WHERE P.CategoryID = @CategoryID
    GROUP BY P.ProductID, P.ProductName
    ORDER BY SUM(OD.Quantity) DESC;

    RETURN;
END
GO

-- Ejemplo:
SELECT * FROM dbo.TopProductosPorCategoria(1, 5);



-- 6)ProductosVendidosEnRango(@FechaIni, @FechaFin)
--Devuelve todos los productos vendidos dentro de un rango de fechas, con cantidad total vendida, ordenados de mayor a menor.

IF OBJECT_ID('dbo.ProductosVendidosEnRango','IF') IS NOT NULL
    DROP FUNCTION dbo.ProductosVendidosEnRango;
GO

CREATE OR ALTER FUNCTION dbo.ProductosVendidosEnRango
(
    @FechaInicio date,
    @FechaFin date
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        P.ProductID,
        P.ProductName,
        SUM(OD.Quantity) AS TotalVendido,
        SUM(OD.Quantity * OD.UnitPrice * (1 - OD.Discount)) AS TotalImporte
    FROM dbo.[Order Details] OD        
    JOIN dbo.Products P ON OD.ProductID = P.ProductID
    JOIN dbo.Orders O  ON O.OrderID = OD.OrderID
    WHERE O.OrderDate BETWEEN @FechaInicio AND @FechaFin
    GROUP BY P.ProductID, P.ProductName
);
GO

-- EJEMPLO:
 SELECT * FROM dbo.ProductosVendidosEnRango('1997-01-01','1997-12-31');


--7)CantidadPedidosPais(@Pais)
--Funcion escalar: Devuelve la cantidad de pedidos enviados a un país específico.
IF OBJECT_ID('dbo.CantidadPedidosPais','FN') IS NOT NULL
    DROP FUNCTION dbo.CantidadPedidosPais;
GO

CREATE OR ALTER FUNCTION dbo.CantidadPedidosPais
(
    @Pais nvarchar(40)
)
RETURNS int
AS
BEGIN
    DECLARE @Cantidad int;

    SELECT @Cantidad = COUNT(*)
    FROM Orders
    WHERE ShipCountry = @Pais;

    RETURN @Cantidad;
END
GO

-- EJEMPLO:
SELECT dbo.CantidadPedidosPais('Germany') AS TotalPedidos;

-- ========== PUBS ==========
USE pubs;
GO

-- 8) AutoresSinLibros
-- Función tabla INLINE: autores que no aparecen en titleauthor (no tienen títulos asignados).

IF OBJECT_ID('dbo.AutoresSinLibros','IF') IS NOT NULL
    DROP FUNCTION dbo.AutoresSinLibros;
GO

CREATE OR ALTER FUNCTION dbo.AutoresSinLibros()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        A.au_id,
        A.au_lname,
        A.au_fname,
        A.city
    FROM dbo.authors A
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.titleauthor TA WHERE TA.au_id = A.au_id
    )
);
GO

-- Ejemplo:
SELECT * FROM dbo.AutoresSinLibros();



--9) TitulosNoVendidos
--   Función tabla INLINE: títulos en 'titles' que no aparecen en 'sales' (no han sido vendidos).
--   Devuelve 4 campos: title_id, title, type, price

IF OBJECT_ID('dbo.TitulosNoVendidos','IF') IS NOT NULL
    DROP FUNCTION dbo.TitulosNoVendidos;
GO

CREATE OR ALTER FUNCTION dbo.TitulosNoVendidos()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        T.title_id,
        T.title,
        T.type,
        T.price
    FROM dbo.titles T
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.sales S WHERE S.title_id = T.title_id
    )
);
GO

-- Ejemplo:
SELECT * FROM dbo.TitulosNoVendidos();



-- 10) PrecioMedioPublisher
--   Función escalar: devuelve el precio promedio (AVG) de los títulos de un publisher.
--   Si no tiene títulos, devuelve NULL.

IF OBJECT_ID('dbo.PrecioMedioPublisher','IF') IS NOT NULL
    DROP FUNCTION dbo.PrecioMedioPublisher;
GO

CREATE OR ALTER FUNCTION dbo.PrecioMedioPublisher
(
    @PubID varchar(4)
)
RETURNS decimal(18,2)
AS
BEGIN
    DECLARE @AvgPrice decimal(18,2);

    SELECT @AvgPrice = AVG(CONVERT(decimal(18,2), T.price))
    FROM dbo.titles T
    WHERE T.pub_id = @PubID;

    RETURN @AvgPrice;
END
GO

-- Ejemplo:
SELECT dbo.PrecioMedioPublisher('0736') AS PrecioPromedio;
