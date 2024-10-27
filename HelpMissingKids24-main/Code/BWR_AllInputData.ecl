IMPORT Visualizer,STD,$;
HMK := $.File_AllData;


McByState := HMK.mc_byStateDS;
PovRates := HMK.pov_estimatesDS;
PolicePop := HMK.PoliceDS;
Pop_total := HMK.pop_estimatesDS;



/*
OUTPUT(HMK.unemp_ratesDS,NAMED('US_UnempByMonth'));
OUTPUT(HMK.unemp_byCountyDS,NAMED('Unemployment'));
OUTPUT(HMK.EducationDS,NAMED('Education'));
OUTPUT(HMK.pov_estimatesDS,NAMED('Poverty'));
OUTPUT(HMK.pop_estimatesDS,NAMED('Population'));
OUTPUT(HMK.PoliceDS,NAMED('Police'));
OUTPUT(HMK.FireDS,NAMED('Fire'));
OUTPUT(HMK.HospitalDS,NAMED('Hospitals'));
OUTPUT(HMK.ChurchDS,NAMED('Churches'));
OUTPUT(HMK.FoodBankDS,NAMED('FoodBanks'));
OUTPUT(HMK.mc_byStateDS,NAMED('NCMEC'));
OUTPUT(COUNT(HMK.mc_byStateDS),NAMED('NCMEC_Cnt'));
OUTPUT(HMK.City_DS,NAMED('Cities'));
OUTPUT(COUNT(HMK.City_DS),NAMED('Cities_Cnt'));


*/




PovMC := RECORD
 String20 state;
 INTEGER  Pov_Rate;
 INTEGER MC;
END;

//police by state count
police_Cnt := TABLE(PolicePop,{population,state,status},state);
OUTPUT(SORT(police_Cnt,-status),NAMED('PolicePopulation'));


//State count table
CT_ST := TABLE(HMK.mc_byStateDS,{missingstate,cnt := COUNT(GROUP)},missingstate);
OUTPUT(SORT(CT_ST,-cnt),NAMED('MissByState'));
 
 //poverty table
POVTBL := TABLE(PovRates((STD.Str.Find(attribute, 'POVALL_2021',1) <> 0)),
              {attribute,value,State});
OUTPUT(SORT(POVTBL,-value),NAMED('PovertyPct0to17'));




//join between state count and povertyRate

ADDPOV := JOIN(CT_ST,POVTBL,
    LEFT.missingstate = RIGHT.State,
               TRANSFORM(PovMC,
               SELF.Pov_Rate := RIGHT.value,
                        SELF.MC := LEFT.CNT,
                        SELF := RIGHT),LEFT OUTER,LOOKUP);
    OUTPUT(ADDPOV,NAMED('mainOutput'));



//population table and output by state
POP_STATE := TABLE(Pop_total,{state,attribute,value},state);
OUTPUT(SORT(POP_STATE,-value), NAMED('popByState'));


cleanPop := RECORD
        STRING20 State;
        INTEGER Pov_Rates;
        INTEGER Mc;
        INTEGER   popByState;
       // INTEGER  popPOV := SELF.Pov_Rates/SELF.popByState;
      //  INTEGER  popMC := SELF.Mc/SELF.popByState;
END;

newDataPOV := JOIN(ADDPOV, POP_STATE,
            STD.Str.ToUpperCase(LEFT.State) = STD.Str.ToUpperCase(RIGHT.state),
            TRANSFORM(cleanPop,
                SELF.Pov_Rates := LEFT.Pov_Rate,
                SELF.Mc := LEFT.MC,
                SELF.popByState := RIGHT.value,
             //   SELF.popPOV := LEFT.Pov_Rate/RIGHT.value,
             //   SELF.popMC := LEFT.MC/RIGHT.value,
                SELF := LEFT;
                SELF := RIGHT));


OUTPUT(newDataPOV, NAMED('newPovPop'));



CleanPovMC :=       JOIN(HMK.pov_estimatesDS,HMK.mc_byStateDS,
                           LEFT.state  = RIGHT.MissingState, 
                           TRANSFORM(HMK.pov_estimates,
                                     SELF := LEFT,
                                     SELF := RIGHT));

// OUTPUT(CleanPovMC,NAMED('PovMC'));


pov2test := RECORD
    ADDPOV.State;
    ADDPOV.Pov_Rate;
    
    END;

newTable := TABLE(ADDPOV, pov2test);

OUTPUT(newTable,NAMED('meeee'));
//NewTabPov := TABLE(ADDPOV,PovMC);
//OUTPUT(Sort(NewTabPov,State), NAMED('theGraph'));
Visualizer.TwoD.Bubble('bubblegraph',,'meeee');


//OUTPUT(CORRELATION(ADDPOV,pov_rate,mc));



//NEW GRAPH 
/*
pov3test := RECORD
    newDataPOV.MC;
    //popPovMC_Rate := (newDataPOV.Pov_Rates/newDataPOV.popByState)
    popPovMRate := CORRELATION(newDataPOV,popPOV,popMC);
END;

povTable := table(newDataPOV,pov3test);
OUTPUT(SORT(povTable,MC),NAMED('povGraphh'));
Visualizer.MultiD.Line('newnewGraaph',,'povGraphh');
//
*/



//Poverty rate by state compared to population
povTest := RECORD
        newDataPOV.state;
        newVal1 := (newDataPOV.Pov_Rates/newDataPOV.popByState)*100;
END;
newPOVTable := TABLE(newDataPOV,povTest);
OUTPUT(newPOVTable,NAMED('povGraph'));
Visualizer.MultiD.Bar('barr',,'povGraph');

//Missing children by state graph
mcTest := RECORD
    newDataPOV.state;
    newVal2 := (newDataPOV.MC/newDataPOV.popByState)*100;
END;

newMCTable := TABLE(newDataPOV,mcTest);
OUTPUT(newMCTable,NAMED('mcGraph'));
Visualizer.MultiD.Bar('bar',,'mcGraph');

//correlation graph for mc

corMC := RECORD
    newDataPOV.state;
    cor1 := CORRELATION(newDataPOV,(newDataPOV.Pov_Rates/newDataPOV.popByState)*100,(newDataPOV.MC/newDataPOV.popByState)*100);
END;

newCorTable := TABLE(newDataPOV,corMC);
OUTPUT(newCorTable,NAMED('CorrelationGraph'));
Visualizer.MultiD.Bar('barrr',,'CorrelationGraph');


/*
corMC := RECORD
    STRING state;
    DECIMAL cor1;
END;

// Calculate correlations for each record and add them to the existing dataset
correlatedData :=  PROJECT(newDataPOV,
    TRANSFORM(corMC, 
                      SELF.state := newDataPOV.state,
                      SELF.cor1 := CORRELATION((SELF.Pov_Rates / SELF.popByState) * 100, (SELF.MC / SELF.popByState) * 100)),
);

// Output the modified dataset
OUTPUT(correlatedData, NAMED('CorrelationGraph'));

// Visualize the correlations by state (assuming 'state' is the X-axis)
Visualizer.MultiD.Bar('barrr',,'CorrelationGraph');
*/


