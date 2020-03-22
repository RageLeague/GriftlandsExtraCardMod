# Notes for specific cards

## Back Down

![Back Down](Gallery/back_down.jpg)

* Removing an argument on your side does not trigger a bounty, while removing an argument on the opponent's side does. This is to avoid a situation where you accidentally removed an opponent bounty without getting the benefits.

## Preach

![Preach](Gallery/preach.jpg)

* **Indoctrination** is a bounty created using **Rise Manifesto**. It has "When dismissed, gain 1 **Dominance** per stack. At the end of each turn, gain 1 **Influence** and reduce this argument by 1."

## Blackmail

![Blackmail](Gallery/blackmail.jpg)

* For **Blackmail** and **Tall Blackmail**, because they are still hostile cards, they are still affected by **Dominance**. Similarly, because **Twisted Blackmail** is still a diplomacy card, it is still affected by **Influence**.
* This card is changed from uncommon to common due to it having to little damage output without synergy.

## DARVO

![DARVO](Gallery/darvo.jpg)

* The amount of damage reflected is rounded down.
* Because damage reflected is still dealt as damage, it will be affected by modifiers such as **Vulnurability**
* Originally, **Draining DARVO** is supposed to negate half of the incoming damage, but I have no idea how to change the damage when an argument is about to take damage, so now it heals instead of damage never happens. Can probably leads to broken combos like heal everything to a ridiculous amount.
* Because trample damage is a seperate instance of damage, this card will try to reflect that damage as well, resulting in more than the expected amount of total damage being reflected.
* The argument created by this card can still reflect damage immediately after it becomes destroyed, but won't reflect trample damage.

## Fake Promise

![Fake Promise](Gallery/fake_promise.jpg)

* **Gain Shills At The End** is a bounty which has "Gain 5 shills at the end of this negotiation for each stacks on this bounty if this bounty still exists, regardless whether you win or lose."
* You have to have at least shills equal to the cost indicated on the card in order to play this. If you don't, then this card becomes a dead card.
* Because there is no event trigger when the game ends, I have to make a workaround for when to give the player the shills. It is very inelegant, so it probably have a lot of bugs. For instance, you probably won't gain anything from the bounties if you concede a negotiation.
* Each **Gain Shills At The End** is created as a seperate instance when the card is used. This will give you many bounties, which can synergize with **Overwhelm**.
