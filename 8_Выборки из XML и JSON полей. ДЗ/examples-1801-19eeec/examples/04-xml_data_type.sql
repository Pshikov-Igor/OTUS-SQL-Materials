DROP TABLE IF EXISTS #table1 
CREATE TABLE #table1 (xmlcol XML)
GO

INSERT #table1 VALUES('<person/>')
INSERT #table1 VALUES('<person></person>')
INSERT #table1 VALUES('<person>

</person>')
GO

-- Представление будет одинаковое
SELECT * FROM #table1 
GO

-- Так будет ошибка. Почему?
INSERT #table1 VALUES('<b><i>abc</b></i>')
INSERT #table1 VALUES('<person>abc</Person>')
GO

SELECT * FROM #table1
GO

-- XML-документ
INSERT #table1 VALUES('<doc/>')
-- Фрагмент документа
INSERT #table1 VALUES('<doc/><doc/>')
-- Только текст 
INSERT #table1 VALUES('Text only')
-- Пустая строка
INSERT #table1 VALUES('') 
-- NULL
INSERT #table1 VALUES(NULL) 

SELECT * FROM #table1

-- XML SCHEMA
-- Можно получить в FOR XML, указав XMLSCHEMA
SELECT CityID,  CityName
FROM Application.Cities
FOR XML RAW('City'), ROOT('Cities'), XMLSCHEMA

-- Создание схемы
-- DROP XML SCHEMA COLLECTION TestXmlSchema
CREATE XML SCHEMA COLLECTION TestXmlSchema AS   
N'
 <xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"
			 xmlns:sqltypes="http://schemas.microsoft.com/sqlserver/2004/sqltypes" 
			 elementFormDefault="qualified">
    <xsd:import namespace="http://schemas.microsoft.com/sqlserver/2004/sqltypes" schemaLocation="http://schemas.microsoft.com/sqlserver/2004/sqltypes/sqltypes.xsd" />
    <xsd:element name="City">
      <xsd:complexType>
        <xsd:attribute name="CityID" type="sqltypes:int" use="required" />
        <xsd:attribute name="CityName" use="required">
          <xsd:simpleType>
            <xsd:restriction base="sqltypes:nvarchar" sqltypes:localeId="1033" sqltypes:sqlCompareOptions="IgnoreCase IgnoreKanaType IgnoreWidth" sqltypes:sqlCollationVersion="2">
              <xsd:maxLength value="50" />
            </xsd:restriction>
          </xsd:simpleType>
        </xsd:attribute>
      </xsd:complexType>
    </xsd:element>
  </xsd:schema>'

-- ---------------------------
-- Использование XML Schema
-- ---------------------------

-- Будет ли так работать?
DECLARE @XmlWithSchema1 XML(TestXmlSchema)
SET @XmlWithSchema1 = '<City CityID="1" CityName="Aaronsburg" />'
GO

-- А так?
DECLARE @XmlWithSchema2 XML(TestXmlSchema)
SET @XmlWithSchema2 = '<City CityID="abc" CityName="Aaronsburg" />'
GO

-- И так?
DECLARE @XmlWithSchema2 XML(TestXmlSchema)
SET @XmlWithSchema2 = '<City CityID="2" CityNameASD="Aaronsburg" />'
GO

-- А здесь?
DECLARE @XmlWithoutSchema1 XML
SET @XmlWithoutSchema1 = '<CityAAA CityID="abc" Name="Aaronsburg" />'
GO

-- ----------------------
-- XQuery
-- ----------------------

use WideWorldImporters

-- DECLARE @x XML
-- SELECT @x = (
--   SELECT TOP 3
--       SupplierID AS [@Id],
--       SupplierName AS [Name],
--       SupplierCategoryName AS [SupplierInfo/Category],
--       PrimaryContact AS [Contact/Primary],
--       AlternateContact AS [Contact/Alternate],
--       WebsiteURL [WebsiteURL],
--       CityName AS [CityName],
--     'SupplierReference: ' + SupplierReference as "comment()"
--   FROM Website.Suppliers
--   FOR XML PATH('Supplier'), ROOT('Suppliers'), TYPE)

-- Чтение XML из файла
-- !!! Для запуска примера изменить путь к файлу data.xml,
-- чтобы соответствовал вашему расположению

DECLARE @x XML
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'D:\otus\ms-sql-server\2021-03\08-xml_json_hw\examples\04-xml_data_type.xml',
   SINGLE_CLOB) as d)

-- value(XQuery/XPath, Type) - возвращает скалярное (единичное) значение
-- query(XQuery/XPath) - возвращает XML
-- exists(XQuery/XPath) - проверяет есть ли данные; 0 - not exists, 1 - exists

SELECT 
   ltrim(@x.value('(/Suppliers/Supplier/@Id)[1]', 'int')) as [Id],
   ltrim(@x.value('(/Suppliers/Supplier/Name)[1]', 'varchar(100)')) as [SupplierName],
   ltrim(@x.value('(/Suppliers/Supplier/SupplierInfo/Category)[1]', 'varchar(100)')) as [Category],

   @x.query('(/Suppliers/Supplier/Contact)[1]') as [Query_Contact],
   
   @x.query('/Suppliers/Supplier/Name[text() = "Contoso,Ltd."]') as [Query_Contoso],
   @x.exist('/Suppliers/Supplier/Name[text() = "Contoso,Ltd."]') as [Exist_Contoso],
  
   @x.query('/Suppliers/Supplier/Name[text() = "Microsoft"]') as [Query_Microsoft],
   @x.exist('/Suppliers/Supplier/Name[text() = "Microsoft"]') as [Exist_Microsoft],

   @x.query('count(//Supplier)') as [SupplierCount]
GO 

-- nodes(XQuery/XPath) - возвращает представление строк для XML
-- Можно использовать вместо OPENXML


DECLARE @x XML
SET @x = (SELECT * FROM OPENROWSET  (BULK 'D:\otus\ms-sql-server\2021-03\08-xml_json_hw\examples\04-xml_data_type.xml', SINGLE_BLOB)  as d)

SELECT  
  t.Supplier.value('(@Id)[1]', 'int') as [Id],
  t.Supplier.value('(Name)[1]', 'varchar(100)') as [SupplierName],
  t.Supplier.value('(SupplierInfo/Category)[1]', 'varchar(100)') as [Category],

  t.Supplier.query('.')
FROM @x.nodes('/Suppliers/Supplier') as t(Supplier)

SELECT 

FROM @x

GO

-- modify()
-- на самостоятельное изучение
-- http://www.sql-tutorial.ru/ru/book_xml_data_type_methods/page5.html