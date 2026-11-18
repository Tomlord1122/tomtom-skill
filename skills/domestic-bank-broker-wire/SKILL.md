---
name: domestic-bank-broker-wire
description: >-
  Answer how to fund a named foreign broker from a named domestic bank by wire. Use when the user asks the deposit steps, fees, or whether online banking is enough, and the broker page, the bank charge schedule, and blogs disagree. Also use when they name a second bank, say online banking is already open but the payee is not designated, paste an ACH or routing screenshot into a SWIFT form, or ask which blank is the sending bank versus the beneficiary. Also use when they ask whether a saved designated payee must be reset every deposit, whether the broker's receiving bank or virtual account usually changes, or where account benefits live in the bank app and whether those benefits waive the wire fee. Do not use when the fee URL is only navigation, when the conflict is SaaS plan prices, or when the page is a venue, statute, or garbled CJK fetch.
tags:
  - research
  - finance
metadata:
  cometline:
    origin: self-improvement
---

# Domestic bank to broker wire

Answer the transfer procedure. Do not paste a beneficiary account from an article, and do not copy one from the wrong rail on the user's own screenshot.

## 1. Fetch the two official pages, then a field-mapping guide

1. `web_search` the broker's regional funding FAQ (residence country + deposit method + "wire" or the local word for outward remittance).
2. `web_search` the sending bank's own outward-remittance or charge-schedule page. Use the product phrase from that page (`國外匯出匯款`, "outward remittance"), not `OR` plus a year. Year-OR queries match encyclopedias and miss the tariff.
3. `web_search` one practitioner guide only for which wire-instruction field maps to which bank form blank.
4. `web_fetch` the broker FAQ and the bank remittance URL. If a fee URL is only menus, stop and use the nav-recovery skill. Do not invent a tariff. If the body is huge navigation but the fee sentence is in it, use that sentence. Do not refetch the same blog; a second fetch repeats it.
5. Skip binary PDF application forms once the HTML charge page has the numbers. A broker wire-instruction PDF that returns as a binary stream is not a substitute for the user's current notification.

## 2. Take hard constraints from the broker page

Record only what that page says:

- Supported currencies, and any local currency that is rejected (a local-currency wire is returned and the bank may charge a refund fee).
- Same-name rule: the sending account must match the broker account holder.
- Deposit methods for that currency. A method absent from the list is not available. Direct ACH, domestic routing, and Bank Wire are different rails even when the same broker page shows both.
- Whether a deposit notification is required before the wire, and that the notification does not move money.
- That the broker does not charge a deposit fee, if the page says so. Correspondent and receiving-bank fees are separate.
- Whether the notification itself has an expiry. If the official page does not state a deadline, do not invent one from a blog. Say the notice stays pending until the wire arrives or the user cancels it.

## 3. Take channel and price from the sending bank's page

1. Quote the channel rule, not a summary from a roundup. Many banks allow web and app wires only after a branch has designated that beneficiary. Counter wires are the undesignated path.
2. Quote handling fee, cable fee, and full-amount / OUR add-on from the charge schedule. If a roundup prints a different digital tariff (percent plus cable plus a different OUR add-on), cite the bank page and do not average or mention the roundup number.
3. Full-amount / OUR means the sender pays so correspondent charges are not taken from principal before the beneficiary bank. It does not mean the beneficiary bank's incoming fee is zero.
4. Sending-bank SWIFT is the origin code for the broker's "sending institution" field. It is not the beneficiary bank. Confirm it on a SWIFT directory when the remittance page does not print it.

## 4. Never publish beneficiary details from a blog

1. Tell the user to create the broker deposit notification first and copy beneficiary name, account or virtual account (VAN), bank name, SWIFT/ABA, address, and payment reference from that screen.
2. Say why: the receiving bank and virtual account are allocated per notification and can change. An old screenshot, a saved designated account, or another person's instruction will miss the account. The user's own broker account id and legal name do not change; the receiving bank, SWIFT, ABA, and VAN can.
3. Map blanks in the abstract: currency from the instruction, beneficiary name as printed (often the broker entity, not the user's name), account = the VAN when the instruction says VAN, reference = broker account id plus the name on the account. Do not fill those with numbers from an article.
4. Each new deposit needs a fresh notification. If the bank, SWIFT, ABA, or account differs from the designated payee, the bank designation must be updated. Reusing the first designation fails. If those four match the saved payee, the existing designation can be reused.
5. A required phone or address blank that the wire instruction omits is a bank-form field, not a wire-routing field. Use the broker entity's published headquarters contact, say the bank will not dial it to complete the wire, and do not invent a department extension. Leave an attachment blank when the instruction does not require one.

## 5. A screenshot of the wrong rail is not the wire instruction

When the user pastes a funding screen and asks what to type into the sending bank:

1. Read the method label on that screen before mapping any number. Routing number, ABA used for ACH, and a domestic account number are not SWIFT and not the wire VAN.
2. If the page says ACH, Direct ACH, or domestic transfer, stop. Tell them to go back, choose Bank Wire, select the currency, and generate the wire instruction. Do not fill the bank's SWIFT blank with the routing number, and do not assume the ACH account number equals the wire VAN.
3. On the wire instruction, map by label, not by length. SWIFT/BIC is 8 or 11 letters (a trailing `XXX` is the branch suffix, keep it). A 9-digit number beside it is the wire ABA; fill it only if the bank form has an ABA blank. The account blank is the instruction's Account Number or VAN, which may embed the broker account id. The payment reference is filled when sending, not when saving the payee, unless that form asks for it.
4. The broker's "sending institution" or "bank you are sending from" field is the user's domestic bank, not the broker's receiving bank. Its account number is the user's own foreign-currency account at that bank, not the VAN.

## 6. Online banking open is not a designated payee

When the user says internet banking already works and only the payee is missing:

1. Re-read the bank's channel sentence. Do not infer an in-app "add overseas payee" flow.
2. Split "open a foreign-currency account" from "designate an outward payee". A 2022-style notice that the account must be opened at a branch does not mean every later payee is counter-only.
3. If the bank's own app or video-service page lists this payee type (foreign-currency designated account, overseas beneficiary), the path is that flow: ID, video check on business days, then a review delay before the payee appears in the transfer menu. Do not send them to a branch because a blog still says counter-only.
4. If web and app both say "after the branch designates the beneficiary", or the app has no such option and tells them to visit, the next step is one branch visit with ID, passbook, seal, and the current wire instruction. They do not re-apply for online banking.
5. A search for "designate online" that returns the same official page plus unrelated year hits is enough. Do not keep searching until a blog invents an online path. Also do not treat a practitioner roundup as the channel rule when the bank page is silent; say the option is in-app only if the bank page or the user's own menu shows it.
6. Do not send the wire during the designation review. The payee is not selectable until the bank says it is active. After it is active, regenerate the broker instruction and compare receiving bank, SWIFT, ABA, and VAN before using the saved payee.

## 7. A saved payee is reused only when the new instruction matches

When the user asks whether they must re-designate, video-verify, or visit the branch every time:

1. The bank designation is a saved payee, not a one-time wire. After it is active, later wires to that same payee do not repeat the video check or the branch visit.
2. Still generate a fresh broker deposit notification before each wire. Compare receiving bank, SWIFT/BIC (keep a trailing branch suffix such as `XXX`), ABA if the form has one, and VAN or account number with the saved payee. If those match, select the saved payee. If any differs, add or update the designation; do not send to the old payee.
3. Do not promise the instruction never changes. Official pages usually do not. A VAN that embeds the user's own broker account id is a stability clue, not a guarantee. The allocation can move when the broker changes receiving bank or assigns that notification to another bank. Say it usually stays for the same person and the same wire rail, then name the four fields to recheck.
4. Recurring broker purchases do not pull from the domestic bank. The bank wire only funds the broker cash balance. A monthly buy from an empty balance is skipped; batching wires is a fee choice, not a designation reset.
5. Do not treat a third-party "instructions never change" post as the rule when the broker page is silent. Absence of a change log is not a promise. Quoted-phrase searches that return only a search-engine URL are a non-read; do not invent a change rate from them.

## 8. Bank VIP benefits are not the wire tariff

When the user asks where to see their account benefits, or whether a status waives the outward wire:

1. There is often no single "my account benefits" page. Split wealth or VIP status, card cashback tier, and campaign banners. Each has its own menu. Do not invent a tap path the bank page does not print; name the status labels the official page uses and say card tier is a different product.
2. Quote the status threshold and what it actually discounts from that product's page: domestic transfer count, FX spread, fund subscription. An FX-spread discount is not the outward cable fee and not the full-amount / OUR add-on.
3. Waive the wire fee only if the charge schedule or the benefit page names outward remittance, cable, or full-amount. If those pages are silent, say the wire tariff still applies. Do not infer a waiver from VIP status.
4. A cheaper in-app rail on the campaign page is still the second-product test below. A small-value or card remittance that cannot carry the broker VAN and reference does not replace the designated SWIFT payee.

## 9. A second bank or a second product is a new tariff

1. When the user names another bank, refetch that bank's charge schedule and designation rule. Do not carry the first bank's fees, SWIFT, or branch rule.
2. If that bank also sells a cheaper non-SWIFT rail (Visa Direct, small-value, bill pay, e-wallet), open that product's own page. Use it only if both are true: the broker's method list includes it, and the product page does not say brokers accept SWIFT only.
3. Reject the cheap rail when its form asks for a domestic clearing code (ACH ABA, sort code) instead of the wire ABA/SWIFT on the broker instruction, or when the bank's comparison table says the broker product is SWIFT-only. Also reject it when the form cannot carry the broker payment reference. Recommend the SWIFT path and its digital fee, not the promo fee on the other rail.
4. Still require a foreign-currency balance for SWIFT. A product that debits local currency and converts inside the app is a different rail, not a shortcut for the same wire.

## 10. What to say

Lead with the rail (SWIFT, not ACH or local transfer), the unsupported currency, the same-name rule, and whether a branch designation is still required. Then the notification-before-wire order, the fee lines from the bank page, and the pitfalls: changing receiving bank, reference line, OUR not covering the receiving bank. If they pasted the wrong screen, name the two numbers not to type and the two labels to copy from the wire page. If the payee is already active, say reuse it only after the four fields match, and do not call that a guarantee the instruction never changes. If they ask about account benefits, separate VIP, card tier, and campaigns, and do not waive the wire fee unless a page names it. Point at the official URLs. Do not tell the user to save the answer into a wiki unless they ask.

## Pitfalls

- A blog's beneficiary name, VAN, or SWIFT is someone else's allocation. Publishing it sends the wire to the wrong account.
- An ACH routing number and a wire ABA can both be 9 digits. The method label, not the digit count, decides which blank they fill.
- "Online banking is open" does not mean this payee is designated. The fee for a designated digital wire does not apply until that payee exists.
- A bank notice that foreign-currency accounts open at a branch is not a rule that every later payee is counter-only. Read the app's own designated-account page before sending them back.
- OUR / full-amount is not "zero fees". The sending bank still charges cable and the OUR add-on; the receiving bank may still charge.
- A cheaper bank product that cannot carry the broker reference is not a discount on the same wire.
- Reusing a saved payee without regenerating the notification fails when the broker assigns a different receiving bank or VAN. Matching four fields is the test; "usually stable" is not permission to skip it.
- A VIP FX-spread discount, a domestic transfer waiver, and a small-value remittance promo are different products. None of them waives the outward cable fee unless that page says so.