import * as Effect from 'effect/Effect'
import * as HttpClient from 'effect/http/HttpClient'
import * as HttpClientResponse from 'effect/http/HttpClientResponse'
import { expect } from 'vitest'

import * as Cloudflare from '@alchemy.run/cloudflare'
import * as Test from '@alchemy.run/test/Vitest'

import Stack from '../alchemy.run'

// No `dev` flag here: `ALCHEMY_DEV=1` runs this file on local workerd, and
// the same file can later run against a real stage.
const { test, beforeAll, afterAll, deploy, destroy } = Test.make({
  providers: Cloudflare.providers(),
})

const stack = beforeAll(deploy(Stack))

const appUrl = Effect.gen(function* () {
  const { url } = yield* stack
  if (url === undefined) {
    return yield* Effect.die(new Error('The stack has no url'))
  }
  return url
})

afterAll(destroy(Stack))

const getVisits = (url: string) =>
  HttpClient.get(`${url}/api/visits`).pipe(
    Effect.flatMap(HttpClientResponse.filterStatusOk),
    Effect.flatMap(response => response.json),
  )

test(
  'counts each visit',
  Effect.gen(function* () {
    const url = yield* appUrl

    const first = yield* getVisits(url)
    const second = yield* getVisits(url)

    expect(first).toEqual({ visits: 1 })
    expect(second).toEqual({ visits: 2 })
  }),
)

test(
  'serves the app',
  Effect.gen(function* () {
    const url = yield* appUrl

    const response = yield* HttpClient.get(url)

    expect(response.status).toBe(200)
    expect(yield* response.text).toContain('<div id="root">')
  }),
)
