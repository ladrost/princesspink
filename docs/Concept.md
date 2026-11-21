# PrincessPink
## Idea
Human Reproduction with a pen and paper roleplay interface such as AD&D and some comic art to visualize the face of the characters within it.

## Goal of the simulation
The goal of Princess Pink is to create a simulation of human reproduction in a scientific way without being pornografic or violent. The pen and paper roleplay interface is meant to gamify the simulation and to play with the simulation. 

## Character sheets
All character sheets are designed to inform the simulation about the attributes and genetics of the character, such that the simulation is able to simulate the procreation of new character by simulating the biological conception, life and death of every character. The simulation will show no pictures of violence or nudity.
The simulation will only include some comic art to visualize the face of the characters on the character sheet, such that players are able to get an idea of the character he/she is playing.

## No violence, no nudity
The simulation will not include any violence, gore, nudity or other content that may be considered offensive or inappropriate. This is the big difference to other role play games like AD&D or World of Warcraft. Princess Pink is NOT about killing others or monsters. It is also not about nudity. It is only about human beings and reproduction of human life. It is a population simulation not an adventure role playing game.

## Architecture
Microservices written in Go and deployed on Kubernetes running on Microsoft Azure using the AKS service.

Glossary

Agent / Character An agent within the simulation is similar to a character within a role playing game. In Princess Pink all agents are characters. Characters can be played by a player. Each character has a unique uuid with which it can be found within the system before birth, during life and after death. Each character is connect to a player, who may play the character and see the character sheet of the character.

Player/ User All users in Princess Pink are players within the simulation. They have access to the character sheets of their characters which they own and play. Each player will have a unique uuid with which it can be found within the system this way connecting players and characters is easy.