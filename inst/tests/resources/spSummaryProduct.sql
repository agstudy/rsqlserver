IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spSummaryProduct]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spSummaryProduct]
GO
CREATE PROCEDURE [dbo].[spSummaryProduct]
   @statistic  char(6)
  ,@value  float OUTPUT
  AS
  BEGIN
  IF NULLIF(@statistic, '') IS NULL
     BEGIN
      IF @statistic = 'sum' 
         SELECT @value = (SELECT sum(value) FROM T_PRODUCT)
      ELSE IF @statistic = 'mean'
         SELECT @value = (SELECT avg(value) FROM T_PRODUCT)
      ELSE IF @statistic = 'median'
         SELECT @value = (Select Top 1 value
                          	From   (
                          			Select Top 50 Percent value
                          			From	T_PRODUCT
                          			Where	value Is NOT NULL
                          			Order By value
                          			) As A
                          	Order By value DESC)
     END
  RETURN
  
  END


