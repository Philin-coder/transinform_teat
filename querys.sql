create proc ins_dep
@DEPARTMENT_NAME varchar(100)
as
begin
	insert into DEPARTMENT(DEPARTMENT_NAME)values(@DEPARTMENT_NAME)
end
/*
exec ins_dep '����������'
select * from DEPARTMENT
*/
alter proc ins_employee
@EMPLOYEE_DEPARTMENT_ID int ,
--@EMPLOYEE_CHIEFF_ID int, 
@EMPLOYEE_NAME varchar(100),
@EMPLOYEE_SALARY decimal(10,2)
as
begin
	insert into EMPLOYEE(EMPLOYEE_DEPARTMENT_ID, EMPLOYEE_NAME,EMPLOYEE_SALARY)
	values(@EMPLOYEE_DEPARTMENT_ID, @EMPLOYEE_NAME,@EMPLOYEE_SALARY)
end
--exec ins_employee  2,'������ �.�', 39.000
select * from EMPLOYEE
create proc get_chif
@EMPLOYEE_CHIEFF_ID int,
@EMPLOYEE_DEPARTMENT_ID int,
@EMPLOYEE_ID int 
as
begin
  update  EMPLOYEE set EMPLOYEE_CHIEFF_ID =1 where EMPLOYEE_DEPARTMENT_ID=@EMPLOYEE_DEPARTMENT_ID and @EMPLOYEE_ID=@EMPLOYEE_ID and EMPLOYEE_CHIEFF_ID is null
end

--1.	������� ������ �����������, ���������� ���������� ����� �������, ��� � ����������������� ������������

	select EMPLOYEE.EMPLOYEE_NAME, EMPLOYEE.EMPLOYEE_SALARY 
	 from EMPLOYEE 
	 where EMPLOYEE.EMPLOYEE_SALARY>(select   EMPLOYEE.EMPLOYEE_SALARY from EMPLOYEE where EMPLOYEE.EMPLOYEE_CHIEFF_ID is not null)
--2.	������� ������ �����������, ���������� ������������ ���������� ����� � ����� ������.
select EMPLOYEE.EMPLOYEE_NAME,EMPLOYEE.EMPLOYEE_SALARY
 from EMPLOYEE 
 where EMPLOYEE.EMPLOYEE_SALARY=(select MAX(EMPLOYEE.EMPLOYEE_SALARY) from EMPLOYEE,DEPARTMENT where EMPLOYEE.EMPLOYEE_DEPARTMENT_ID=DEPARTMENT.DEPARTMENT_ID)
 --3.	������� ������ ID �������, ���������� ����������� � ������� �� ��������� ��� �������.
 select EMPLOYEE.EMPLOYEE_DEPARTMENT_ID
from   EMPLOYEE
group  by  EMPLOYEE_DEPARTMENT_ID
having count(*) <= 3
--4.	������� ������ �����������, �� ������� ������������ ������������, ����������� � ��� �� ������.
select * from EMPLOYEE
left join DEPARTMENT on DEPARTMENT.DEPARTMENT_ID=EMPLOYEE_CHIEFF_ID
where DEPARTMENT.DEPARTMENT_ID is null

--5.	����� ������ ID ������� � ������������ ��������� ��������� �����������.
WITH dep_salary AS 
	(SELECT  EMPLOYEE_DEPARTMENT_ID, sum(EMPLOYEE_SALARY) AS salary
	FROM EMPLOYEE 
	GROUP BY EMPLOYEE_DEPARTMENT_ID)
SELECT EMPLOYEE_DEPARTMENT_ID
FROM dep_salary
WHERE dep_salary.salary = (SELECT max(salary) FROM dep_salary);


CREATE FUNCTION [dbo].[fFindMiddleSubstring]
(
  @Source varchar(max),
  @LeftSubstring varchar(500),
  @RightSubstring varchar(500),
  @StartPos int,
  @TrimEx int
)
RETURNS 
@RsltTable TABLE 
(
  ResString varchar(max),
  EndPos int
)
AS
BEGIN

DECLARE @EndPos int,
        @MiddleSubstring varchar(max)

SET @EndPos = CHARINDEX(@RightSubstring, @Source, @StartPos)

IF @EndPos = 0
BEGIN
    SET @EndPos = LEN(@Source) + 1
END

SET @MiddleSubstring = SUBSTRING(@Source, @StartPos, @EndPos - @StartPos)

IF(@TrimEx & 1) = 1
    SET @MiddleSubstring = LTRIM(RTRIM(@MiddleSubstring))

IF(@TrimEx & 2) = 2
    SET @MiddleSubstring = REPLACE(@MiddleSubstring, CHAR(160), '')

IF(@TrimEx & 4) = 4
    SET @MiddleSubstring = REPLACE(@MiddleSubstring, CHAR(160), ' ')

IF(@TrimEx & 8) = 8
    SET @MiddleSubstring = REPLACE(@MiddleSubstring, '&quot;', '"')

IF(@TrimEx & 16) = 16
    BEGIN
        SET @MiddleSubstring = REPLACE(@MiddleSubstring, '.', '')
        SET @MiddleSubstring = REPLACE(@MiddleSubstring, ',', '.')
    END

IF(@TrimEx & 32) = 32
    SET @MiddleSubstring = REPLACE(@MiddleSubstring, ' ', '')

IF(@TrimEx & 64) = 64
    BEGIN
        SET @MiddleSubstring = REPLACE(@MiddleSubstring, CHAR(13), '')
        SET @MiddleSubstring = REPLACE(@MiddleSubstring, CHAR(10), '')
    END

INSERT INTO @RsltTable (ResString, EndPos) VALUES (@MiddleSubstring, @EndPos)

RETURN

END

CREATE PROCEDURE [dbo].[pFindMiddleSubstring]
  @Source varchar(max),
  @LeftSubstring varchar(500),
  @RightSubstring varchar(500),
  @StartPos int = 1, -- Начальная позиция поиска (по умолчанию 1)
  @TrimEx int = 0, -- Флаг обрезки пробелов (0 - не обрезать, 1 - обрезать)
  @Result varchar(max) output, -- результат
  @EndPos int output -- конечная позиция
AS
BEGIN
  -- Находим позицию начала левой подстроки
  DECLARE @LeftPos int = CHARINDEX(@LeftSubstring, @Source, @StartPos);

  -- Если левая подстрока не найдена, выходим
  IF @LeftPos = 0
    BEGIN
      SET @Result = '';
      SET @EndPos = 0;
      RETURN;
    END

  -- Находим позицию начала правой подстроки
  DECLARE @RightPos int = CHARINDEX(@RightSubstring, @Source, @LeftPos + LEN(@LeftSubstring));

  -- Если правая подстрока не найдена, выходим
  IF @RightPos = 0
    BEGIN
      SET @Result = '';
      SET @EndPos = 0;
      RETURN;
    END

  -- Вычисляем позицию начала и конца искомой подстроки
  SET @Result = SUBSTRING(@Source, @LeftPos + LEN(@LeftSubstring), @RightPos - @LeftPos - LEN(@LeftSubstring));

  -- Обрезаем пробелы, если это необходимо
  IF @TrimEx & 1 = 1
    SET @Result = LTRIM(RTRIM(@Result));

  -- Заменяем неразрывные пробелы на обычные, если это необходимо
  IF @TrimEx & 2 = 2
    SET @Result = REPLACE(@Result, CHAR(160), ' ');

  -- Заменяем кавычки, если это необходимо
  IF @TrimEx & 8 = 8
    SET @Result = REPLACE(@Result, '&quot;', '"');

  -- Заменяем точки и запятые, если это необходимо
  IF @TrimEx & 16 = 16
    BEGIN
        SET @Result = REPLACE(@Result, '.', '');
        SET @Result = REPLACE(@Result, ',', '.');
    END

  -- Удаляем пробелы, если это необходимо
  IF @TrimEx & 32 = 32
    SET @Result = REPLACE(@Result, ' ', '');

  -- Удаляем символы перевода строки, если это необходимо
  IF @TrimEx & 64 = 64
    BEGIN
        SET @Result = REPLACE(@Result, CHAR(13), '');
        SET @Result = REPLACE(@Result, CHAR(10), '');
    END

  -- Записываем конечную позицию
  SET @EndPos = @RightPos;
END

