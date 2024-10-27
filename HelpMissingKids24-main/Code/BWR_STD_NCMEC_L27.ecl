IMPORT STD,$;

NCMEC_Rec := $.File_AllData.mc_byState;
NCMEC_DS  := $.File_AllData.mc_byStateDS;
Cities    := $.File_AllData.City_DS;
UNEMP     := $.File_AllData.unemp_byCountyDS;
EDU       := $.File_AllData.EducationDS;
POVTY     := $.File_AllData.pov_estimatesDS;
POP       := $.File_AllData.pop_estimatesDS;

// OUTPUT(NCMEC_DS);
// Sequence Records
// Standardizing Dates
// Name and Contact Standardization
// Add PrimaryFIPS Field to Dataset
// Cross Tab Reports, By City, State, Date Missing, FIPS
NewNCMECLayout := $.File_EnhanceNCMEC.NCMECPlusLayout;

NewNCMECLayout CleanNCMEC(NCMEC_DS Le,UNSIGNED2 CNT) := TRANSFORM
 // SELF.RecID    := CNT; //Now uses Case Number
 SELF.DatePosted  := STD.Date.FromStringToDate(Le.DatePosted,'%m/%d/%Y');
 SELF.FirstName   := STD.Str.ToUpperCase(Le.FirstName);
 SELF.LastName    := STD.Str.ToUpperCase(Le.LastName);
 // SELF.DateMissing := STD.Date.FromStringToDate(Le.DateMissing,'%m/%d/%Y'); //Processed earlier
 SELF.MissingCity := STD.Str.ToUpperCase(Le.MissingCity);
 SELF.Contact     := STD.Str.ToUpperCase(Le.Contact);
 SELF.PrimaryFIPS := 0; 
 SELF.ump_rate    := 0;
 SELF.pov_pct     := 0;
 SELF.PopEst      := 0;
 SELF.edu_High    := 0;
 SELF             := Le;
 END;
//Step 1: Make room for new metrics, standardize dates, names, contact and sequence records
Clean_NCMEC_DS := PROJECT(NCMEC_DS,CleanNCMEC(LEFT,COUNTER));
OUTClean_NCMEC_DS := OUTPUT(Clean_NCMEC_DS,NAMED('DataCleaned'));

NewNCMECLayout GetFIPS(Clean_NCMEC_DS Le,Cities Ri) := TRANSFORM
SELF.PrimaryFIPS := (UNSIGNED3)Ri.county_fips;
SELF             := Le; 
END;

AddFIPS := JOIN(Clean_NCMEC_DS,Cities,
                LEFT.missingcity = STD.STR.ToUpperCase(RIGHT.city) AND
                LEFT.missingstate = RIGHT.state_id,
                GetFIPS(LEFT,RIGHT),LEFT OUTER);
Out_addFips := OUTPUT(AddFips,NAMED('FIPSAdded'));

// OUTPUT(AddFips(PrimaryFIPS = 6025));


//Cross-Tab by City: 

CT_City := TABLE(AddFIPS,{missingcity,missingstate,cnt := COUNT(GROUP)},missingstate,missingcity);
Out_CT_City := OUTPUT(SORT(CT_City,-cnt),NAMED('MissByCity'));

//Cross-Tab by State:

CT_ST := TABLE(AddFIPS,{missingstate,cnt := COUNT(GROUP)},missingstate);
Out_CT_ST := OUTPUT(SORT(CT_ST,-cnt),NAMED('MissByState'));
