# Twenty20

A tiny macOS app that reminds you to rest your eyes.

Every 20 minutes it covers the top of your screen for 20 seconds —
time to look 20 feet away. That's the 20-20-20 rule.

- Menu bar icon with countdown, "Break now", "Skip", "Pause 30 min"
- Won't disturb fullscreen apps or steal focus
- Pauses while you're away, remembers nothing else

## Install

Download `Twenty20.zip` from the latest [Actions run](../../actions),
unzip, then right-click → Open (it's unsigned, so Gatekeeper asks once).

Or build it yourself: `./scripts/package_app.sh` then `open build/Twenty20.app`.
