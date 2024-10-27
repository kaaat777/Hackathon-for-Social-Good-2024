IMPORT STD,$;

//This file is used to demonstrate how to "clean" a raw dataset (Churches) and create an index to be used in a ROXIE service
PovertyRates := $.File_AllData.pov_estimatesDS;
missingKids   := $.File_AllData.mc_byStateDS;


//First, determine what fields you want to clean:
CleanPovertyRec := RECORD
    UNSIGNED3 FIPS_Code;
    STRING2   State;
    STRING35  Area_name;
    STRING35   Attribute;
    REAL8      Value; 
END;
//PROJECT is used to transform one data record to another.
CleanPoverty := PROJECT(PovertyRates,TRANSFORM(CleanPovertyRec,
                                          SELF.State                := STD.STR.ToUpperCase(LEFT.State);
                                          SELF.Area_name              := STD.STR.ToUpperCase(LEFT.Area_name);
                                          SELF.Attribute                := STD.STR.ToUpperCase(LEFT.Attribute);
                                          SELF.Value                     := LEFT.Value;
                                          SELF.FIPS_Code                 := LEFT.FIPS_Code;
                                          ));

//JOIN is used to combine data from different datasets 
CleanPovMC :=       JOIN(CleanPoverty,missingKids,
                           LEFT.State  = STD.STR.ToUpperCase(RIGHT.MissingState), 
                           TRANSFORM(CleanPovertyRec,
                                     SELF             := LEFT),LEFT OUTER,LOOKUP);
//Write out the new file and then define it using DATASET
WritePoverty      := OUTPUT(CleanPovMC,,'~HMK::OUT::PovertyRates',NAMED('WriteDS'),OVERWRITE);                                          
CleanChurchesDS    := DATASET('~HMK::OUT::PovertyRates',CleanPovertyRec,FLAT);


/*
//Declare and Build Indexes (special datasets that can be used in the ROXIE data delivery cluster
CleanChurchIDX     := INDEX(CleanChurchesDS,{city,state},{CleanChurchesDS},'~HMK::IDX::Church::CityPay');
CleanChurchFIPSIDX := INDEX(CleanChurchesDS,{PrimaryFIPS},{CleanChurchesDS},'~HMK::IDX::Church::FIPSPay');
BuildChurchIDX     := BUILD(CleanChurchIDX,NAMED('BldIDX1'),OVERWRITE);
BuildChurchFIPSIDX := BUILD(CleanChurchFIPSIDX,NAMED('BLDIDX2'),OVERWRITE);

//Cross-Tab Reports:
//Churches by City: 

CT_City := TABLE(CleanChurchesDS,{city,state,cnt := COUNT(GROUP)},state,city);
Out_CT_City := OUTPUT(SORT(CT_City,-cnt),NAMED('ChurchByCity'));

//Cross-Tab by State:

CT_ST := TABLE(CleanChurchesDS,{state,cnt := COUNT(GROUP)},state);
Out_CT_ST := OUTPUT(SORT(CT_ST,-cnt),NAMED('ChurchByState'));

//Cross-Tab by Primary FIPS:

CT_FIPS := TABLE(CleanChurchesDS,{PrimaryFIPS,cnt := COUNT(GROUP)},PrimaryFIPS);
Out_CT_FIPS := OUTPUT(SORT(CT_FIPS(PrimaryFIPS <> 0),-cnt),NAMED('ChurchByFIPS'));

//SEQUENTIAL is similar to OUTPUT, but executes the actions in sequence instead of the default parallel actions of the HPCC
SEQUENTIAL(WriteChurches,BuildChurchIDX,BuildChurchFIPSIDX,out_Ct_City,Out_Ct_ST,Out_CT_FIPS);

*/