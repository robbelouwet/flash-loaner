import functools

from urllib.request import urlopen
import asyncio


def legacy_blocking_function():  # You cannot change this function
    r = urlopen("https://example.com")
    return r.read().decode()


def run_in_executor(f):
    @functools.wraps(f)
    def inner(*args, **kwargs):
        loop = asyncio.get_running_loop()
        return loop.run_in_executor(None, lambda: f(*args, **kwargs))

    return inner


@run_in_executor
def foo(arg):  # Your wrapper for async use
    resp = legacy_blocking_function()
    return f"{arg}{len(resp)}"


async def process_input(inp):  # Modern async function (coroutine)
    return await foo(inp)


async def main():
    inputs = ["one", "two", "three"]
    input_tasks = [asyncio.create_task(process_input(inp)) for inp in inputs]
    for t in asyncio.as_completed(input_tasks):
        print(await t)
    # This doesn't work as expected :(
    # print([await t for t in asyncio.as_completed([process_input(inp) for inp in input_tasks])])


if __name__ == '__main__':
    asyncio.run(main())
