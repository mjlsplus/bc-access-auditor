tableextension 50960 "BCG Perf Rule Owner" extends "BCG Conflict Header"
{
    fields
    {
        // Persisted even in normal builds: synthetic rules must never affect real runs.
        field(50960; "Perf Dataset ID"; Guid)
        {
            Caption = 'Performance Dataset ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
}
