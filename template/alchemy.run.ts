import * as Alchemy from 'alchemy'
import { ALCHEMY_DEV } from 'alchemy/Phase'
import * as Effect from 'effect/Effect'
import * as Layer from 'effect/Layer'

import * as Cloudflare from '@alchemy.run/cloudflare'

export const Visits = Cloudflare.KV.Namespace('Visits')

export const Website = Cloudflare.Website.Foldkit('Website', {
  main: 'src/worker.ts',
  env: { VISITS: Visits },
  assets: { runWorkerFirst: ['/api/*'] },
})

export type WebsiteEnv = Cloudflare.InferEnv<typeof Website>

// NOTE: Local dev and the Worker test keep state on disk, so they need no
// Cloudflare account. Every other stage keeps it in the account's store.
const state = Layer.unwrap(
  Effect.gen(function* () {
    const dev = yield* Effect.orDie(ALCHEMY_DEV)
    return dev ? Alchemy.localState() : Cloudflare.state()
  }),
)

export default Alchemy.Stack(
  'App',
  {
    providers: Cloudflare.providers(),
    state,
  },
  Effect.gen(function* () {
    const website = yield* Website

    return { url: website.url }
  }),
)
