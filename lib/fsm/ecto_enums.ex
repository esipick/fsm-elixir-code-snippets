import EctoEnum
defenum DateTachEnum, :date_tach, [:date, :tach]
defenum DocumentType, :document_type, [:pilot, :aircraft]
defenum AttachmentType, :attachment_type, [:inspection, :document, :squawk]
defenum SquawkSeverity, :squawk_severity, [:monitor, :warning, :grounded]
defenum SystemAffected, :system_affected, [:fuselage, :cockpit ,:wing, :tail, :engine, :propeller, :landing_gear]