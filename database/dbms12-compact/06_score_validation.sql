SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION dbo.fn_ValidScore(@Text varchar(40)) RETURNS bit AS
BEGIN
    IF @Text IS NULL RETURN 1;
    IF LEN(@Text)=0 OR DATALENGTH(@Text)<>DATALENGTH(LTRIM(RTRIM(@Text))) RETURN 0;
    IF @Text COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9.]%' RETURN 0;
    IF LEN(@Text)-LEN(REPLACE(@Text,'.',''))>1 RETURN 0;
    DECLARE @Dot int=CHARINDEX('.',@Text);
    IF @Dot=1 OR @Dot=LEN(@Text) OR (@Dot>0 AND LEN(@Text)-@Dot>2) RETURN 0;
    IF TRY_CONVERT(decimal(5,2),@Text) IS NULL OR TRY_CONVERT(decimal(5,2),@Text)>100 RETURN 0;
    RETURN 1;
END;
GO
