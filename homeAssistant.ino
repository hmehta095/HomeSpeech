// This #include statement was automatically added by the Particle IDE.
#include <InternetButton.h>

InternetButton button = InternetButton();
int DELAY = 200;
void setup() {
 button.begin();

Particle.function("answer",showCorrectOrIncorrect);

    for(int i=0;i<3;i++){
    button.allLedsOn(200,0,0);
    delay(500);
    button.allLedsOff();   
    delay(500);
    }
}



int showCorrectOrIncorrect(String cmd){
    if(cmd == "green"){
        button.allLedsOn(0,255,0);
        delay(200);
        button.allLedsOff();
    }
    
    else if (cmd == "red"){
        button.playSong("C4,8,E4,8,G4,8,C5,8,G5,4");
    }
    else{
        return -1;
    }
    return 1;
    
}



void loop() {


}
