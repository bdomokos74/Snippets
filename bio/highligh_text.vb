Sub FindAndReplacePrimers()
'
' FindAndReplacePrimers - Find all of the strings in the primers array, and highlight them.
'
' Note: Set the highlight color manually before running this macro.
' Newlines are coded as ^p

Dim primers(0 To 1) As String

primers(0) = "ACACCTGAGTGGATACAAAGAC"
primers(1) = "A^pCACCTGAGTGGATACAAAGAC"

For ipos = LBound(primers) To UBound(primers)

    With Selection.Find
        .Text = primers(ipos)
        .Replacement.Highlight = True
        .Wrap = wdFindContinue
        .Execute Replace:=wdReplaceAll
    End With

Next ipos

End Sub