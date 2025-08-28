import {
  TicketMinted as TicketMintedEvent,
  WinnerPaid as WinnerPaidEvent,
  DrawExecuted as DrawExecutedEvent,
  PrizeClaimed as PrizeClaimedEvent,
} from "../generated/CryloLottoTicket/CryloLottoTicket"

import {
  TicketMinted,
  WinnerPaid,
  DrawExecuted,
  PrizeClaimed,
} from "../generated/schema"

import { BigInt } from "@graphprotocol/graph-ts"

export function handleTicketMinted(event: TicketMintedEvent): void {
  let entity = new TicketMinted(event.transaction.hash.toHex() + "-" + event.logIndex.toString())
  entity.player = event.params.player
  entity.ticketId = event.params.ticketId
  entity.numbers = event.params.numbers
  entity.timestamp = event.block.timestamp
  entity.save()
}

export function handleWinnerPaid(event: WinnerPaidEvent): void {
  let entity = new WinnerPaid(event.transaction.hash.toHex() + "-" + event.logIndex.toString())
  entity.winner = event.params.winner
  entity.amount = event.params.amount
  entity.timestamp = event.block.timestamp
  entity.save()
}

export function handleDrawExecuted(event: DrawExecutedEvent): void {
  let entity = new DrawExecuted(event.transaction.hash.toHex() + "-" + event.logIndex.toString())
  entity.drawId = event.params.drawId
  entity.winningNumbers = event.params.winningNumbers
  entity.timestamp = event.block.timestamp
  entity.save()
}

export function handlePrizeClaimed(event: PrizeClaimedEvent): void {
  let entity = new PrizeClaimed(event.transaction.hash.toHex() + "-" + event.logIndex.toString())
  entity.claimer = event.params.claimer
  entity.ticketId = event.params.ticketId
  entity.prizeAmount = event.params.prizeAmount
  entity.timestamp = event.block.timestamp
  entity.save()
}
