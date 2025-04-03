#pragma comment(lib, "SDL3")

#include "SDL3/SDL.h"
#include "SDL3/SDL_render.h"

int
main(void)
{
 int good = SDL_Init(SDL_INIT_VIDEO|SDL_INIT_EVENTS);

 SDL_Window *window = 0;
 if(good)
 {
  SDL_WindowFlags flags = 0;

#if 1 // TODO(mmacieje): win32 and linux
  flags |= SDL_WINDOW_VULKAN;
#else // TODO(mmacieje): macos
  flags |= SDL_WINDOW_METAL;
#endif

  window = SDL_CreateWindow("sld3", 1280, 720, flags);
  good = (window != 0);
 }

 SDL_Renderer *renderer = 0;
 if(good)
 {
  renderer = SDL_CreateRenderer(window, "direct3d12,vulkan,metal");
  printf("%s\n", SDL_GetRendererName(renderer));
  good = (renderer != 0);
 }

 SDL_Vertex vertices[] =
 {
#define WidthFromVertex(v)  (((v) + 1.f) * (1280 / 2.f))
#define HeightFromVertex(v) ((1.f - (v)) * (720 / 2.f))
  {.position = {WidthFromVertex(-.5f), HeightFromVertex(-.5f)}, .color = {.r = 1.f, .g = .5f, .b = .2f, .a = 1.f}, .tex_coord = {0}},
  {.position = {WidthFromVertex( .5f), HeightFromVertex(-.5f)}, .color = {.r = 1.f, .g = .5f, .b = .2f, .a = 1.f}, .tex_coord = {0}},
  {.position = {WidthFromVertex( .0f), HeightFromVertex( .5f)}, .color = {.r = 1.f, .g = .5f, .b = .2f, .a = 1.f}, .tex_coord = {0}},
 };

 int indices[] = {0, 1, 2};

 for(int quit = 0; quit == 0;)
 {
  SDL_SetRenderDrawColor(renderer, 51, 77, 77, 255);
  SDL_RenderClear(renderer);

#define ArrayCount(v) ((sizeof(v))/(sizeof(*(v))))
  SDL_RenderGeometry(renderer, /* texture */ 0, vertices, ArrayCount(vertices), indices, ArrayCount(indices));
  SDL_RenderPresent(renderer);

  SDL_Event event;
  while(SDL_PollEvent(&event))
  {
   switch(event.type)
   {
    default:{}break;

    case SDL_EVENT_QUIT:
    {
     quit = 1;
    }break;

    case SDL_EVENT_KEY_DOWN:
    {
     if(event.key.key == SDLK_ESCAPE)
     {
      quit = 1;
     }
    }break;
   }
  }
 }

 SDL_DestroyRenderer(renderer);
 SDL_DestroyWindow(window);
 SDL_Quit();

 return 0;
}