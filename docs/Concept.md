# PrincessPink
## Idea
Human biology simulation with a pen and paper roleplay interface such as AD&D and some comic art to visualize the characters within it.

## Goal of the simulation
The goal of Princess Pink is to create a simulation of human procreation. All character sheets are designed to inform the simulation about the attributes and genetics of the character, such that the simulation is able to simulate the procreation of new character by simulation the biological conception, pregnancy, life and death character. 

The simulation will also include some comic art to visualize the character on the character sheet, such that player is able to get an idea of the character he/she is playing.

## No violence
The simulation will not include any violence, gore or other content that may be considered offensive or inappropriate. This is the big difference to other role play games like AD&D or World of Warcraft. Princess Pink is NOT about killing others or monsters. It is only about human beings and procreating new humans. It is a population simulation not an adventure role playing game.

## Architecture
Microservices written in Go and deployed on Kubernetes running on Microsoft Azure using the AKS service.

Glossary

Agent / Character An agent within the simulation is similar to a character within a role playing game. In Princess Pink all agents are characters. Characters can be played by a player. Each character has a unique uuid with which it can be found within the system before birth, during life and after death. Each character is connect to a player, who may play the character and see the character sheet of the character.

Player/ User All users in Princess Pink are players within the simulation. They have access to the character sheets of their characters which they own and play. Each player will have a unique uuid with which it can be found within the system this way connecting players and characters is easy.