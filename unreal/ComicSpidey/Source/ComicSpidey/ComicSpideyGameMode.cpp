#include "ComicSpideyGameMode.h"
#include "ComicSpideyCharacter.h"

AComicSpideyGameMode::AComicSpideyGameMode()
{
    DefaultPawnClass = AComicSpideyCharacter::StaticClass();
}
