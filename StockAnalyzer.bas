Attribute VB_Name = "StockAnalyzer"
Option Explicit

' Sheet Names
Private Const DASHBOARD_SHEET As String = "Dashboard"
Private Const SYMBOL_SHEET As String = "Symbols"
Private Const DESTINATION_RANGE As String = "$D$1" ' destination range for imported data

' URL of Yahoo Finance API for Historical Stock Prices
Private Const YAHOO_URL As String = "http://ichart.finance.yahoo.com/table.csv"


' Main macro called when user press the "Load" button.
' This macro executes all other macros that read user inputs,
' build a valid URL and load data from Yahoo Finance into Excel.
Public Sub Run()
    Dim url As String ' complete and valid URL of Yahoo Finance

    ' clear table containing imported data
    Call ClearData
    
    ' build URL based on user inputs
    url = BuildURL()
    
    ' load data from Yahoo Finance
    Call LoadExternalData(url)
End Sub


' Clear table containing the imported data
Private Sub ClearData()
    ActiveWorkbook.Worksheets(DASHBOARD_SHEET).Range(DESTINATION_RANGE).CurrentRegion.ClearContents
End Sub


' Get user input data from worksheet and prepare the URL.
' Input data: stock, starting date, ending date, and frequency.
'
' @param sheetName: Name of Main Worksheet
'
Private Function BuildURL() As String
    Dim stockSymbol As String
    Dim startDate As Date, endDate As Date
    Dim startYear As Integer, startMonth As Integer, startDay As Integer
    Dim endYear As Integer, endMonth As Integer, endDay As Integer
    Dim frequency As String
    Dim url As String
    
    With ActiveWorkbook.Sheets(DASHBOARD_SHEET)
        ' Get stock symbol
        stockSymbol = .[B2].Value
    
        ' Get starting date and extract day, month  and year
        startDate = .[B3].Value
        startYear = Year(startDate)
        startMonth = Month(startDate) - 1
        startDay = Day(startDate)
        
        ' Get ending date and extract day, month  and year
        endDate = .[B4].Value
        endYear = Year(endDate)
        endMonth = Month(endDate) - 1
        endDay = Day(endDate)
        
        ' Get frequency
        frequency = .[B5].Value
        Select Case frequency
            Case "Daily"
                frequency = "d"
            Case "Weekly"
                frequency = "w"
            Case "Monthly"
                frequency = "m"
            Case "Dividends Only"
                frequency = "v"
            Case Else
                frequency = "" ' unknown frequency
        End Select
        
        ' Build the url based on the extracted values
        ' WARNING: -1 must be substracted from months,
        ' i.e. January = 0, February = 1, ..., December = 11.
        url = YAHOO_URL
        url = url & "?s=" & stockSymbol
        url = url & "&a=" & startMonth
        url = url & "&b=" & startDay
        url = url & "&c=" & startYear
        url = url & "&d=" & endMonth
        url = url & "&e=" & endDay
        url = url & "&f=" & endYear
        url = url & "&g=" & frequency

    End With
    
    BuildURL = url
End Function


' Fetch online data using Yahoo Finance API for Historical Stock Values
'
' @param url:       URL of online API (containing parameters)
' @param sheetName: Name of Worksheet
' @param destRange: Destination Range
'
Private Sub LoadExternalData(url As String)
    Dim q As QueryTable
    Dim s As Worksheet
    Dim r As Range
        
    ' Avoids alert messages when replacing data
    Application.DisplayAlerts = False
    
    ' Set desintation sheet and destination range for the returned data
    Set s = ActiveWorkbook.Sheets(DASHBOARD_SHEET)
    Set r = s.Range(DESTINATION_RANGE)
    
    ' Indicates that the result returned by the URL is a text file.
    url = "TEXT;" & url
    
    ' Fetch online data using QueryTable Object:
    '  - Create a new QueryTable using QueryTables.Add(URL, DestinationRange)
    '  - Use QueryTable.Refresh to send the request to Yahoo Finance API
    '  - Finally, delete the QueryTable using QueryTable.Delete
    Set q = s.QueryTables.Add(url, r)
    With q
        .RefreshStyle = xlOverwriteCells                    ' Replace current cells
        .BackgroundQuery = False                            ' Synchronous Query
        .TextFileParseType = xlDelimited                    ' Parsing Type (column  separated by  a character)
        .TextFileTextQualifier = xlTextQualifierDoubleQuote ' Column Name Delimiter ""
        .TextFileCommaDelimiter = True                      ' Column Separator
        .Refresh
    End With
    
    ' Destroys the QueryTable object (used only once)
    q.Delete
    
    
    ' Re-enables alert messages
    Application.DisplayAlerts = True
End Sub
