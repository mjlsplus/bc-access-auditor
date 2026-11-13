enum 50500 "BCG Severity"
{
    Extensible = true;
    value(0; Low) { Caption = 'Low'; }
    value(1; Medium) { Caption = 'Medium'; }
    value(2; High) { Caption = 'High'; }
    value(3; Critical) { Caption = 'Critical'; }
}

enum 50501 "BCG Object Type"
{
    Extensible = true;
    value(0; "Table Data") { Caption = 'Table Data'; }
    value(1; Page) { Caption = 'Page'; }
    value(2; Report) { Caption = 'Report'; }
    value(3; Codeunit) { Caption = 'Codeunit'; }
    value(4; Query) { Caption = 'Query'; }
}

enum 50502 "BCG Access Type"
{
    Extensible = true;
    value(0; Read) { Caption = 'Read'; }
    value(1; Insert) { Caption = 'Insert'; }
    value(2; Modify) { Caption = 'Modify'; }
    value(3; Delete) { Caption = 'Delete'; }
    value(4; Execute) { Caption = 'Execute'; }
}

enum 50503 "BCG Group Eval Logic"
{
    Extensible = true;
    value(0; ANY) { Caption = 'ANY'; }
    value(1; ALL) { Caption = 'ALL'; }
}

enum 50542 "BCG Table Data Perm Match"
{
    Extensible = true;
    value(0; "Not Required") { Caption = 'Not Required'; }
    value(1; "Direct Only") { Caption = 'Direct Only'; }
    value(2; "Direct or Indirect") { Caption = 'Direct or Indirect'; }
}
