#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "ComicSpideyCharacter.generated.h"

class UCameraComponent;
class USpringArmComponent;

// First migration milestone only: camera-relative keyboard movement and jump.
// Mobile controls, animation, combat, swinging, Story, and saves are not ported.
UCLASS()
class COMICSPIDEY_API AComicSpideyCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AComicSpideyCharacter();
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

private:
    UPROPERTY(VisibleAnywhere, Category="Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, Category="Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    void MoveForward(float Value);
    void MoveRight(float Value);
};
