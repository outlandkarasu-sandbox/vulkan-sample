import std.algorithm : map, each;
import std.stdio : writeln, writefln;
import std.exception : enforce;
import std.conv : to;

import bindbc.sdl :
    loadSDL,
    SDLSupport,
    unloadSDL;

import erupted :
    loadInstanceLevelFunctions,
    VK_MAKE_VERSION,
    VK_NULL_HANDLE,
    VkApplicationInfo,
    vkCreateInstance,
    vkDestroyInstance,
    vkEnumeratePhysicalDevices,
    vkGetPhysicalDeviceProperties,
    VkInstance,
    VkInstanceCreateInfo,
    VkPhysicalDevice,
    VkPhysicalDeviceProperties,
    VkResult;

import erupted.vulkan_lib_loader :
    loadGlobalLevelFunctions;

private void enforceVK(VkResult res)
{
	enforce(res == VkResult.VK_SUCCESS, res.to!string);
}

int main()
{
    switch (loadSDL())
    {
    case SDLSupport.noLibrary:
        writefln("SDL noLibrary");
        return -1;
    case SDLSupport.badLibrary:
        writefln("SDL badLibrary");
        return -1;
    default:
        break;
    }
    scope(exit) unloadSDL();


    loadGlobalLevelFunctions();

    VkApplicationInfo appInfo = {
        pApplicationName: "Vulkan sample",
        apiVersion: VK_MAKE_VERSION(1, 0, 2),
    };
    VkInstanceCreateInfo instInfo = {
        pApplicationInfo: &appInfo,
    };

    VkInstance instance;
    enforceVK(vkCreateInstance(&instInfo, null, &instance));
    loadInstanceLevelFunctions(instance);

    scope(exit)
    {
        if (instance != VK_NULL_HANDLE)
        {
            vkDestroyInstance(instance, null);
        }
    }

    uint numPhysDevices;
    enforceVK(vkEnumeratePhysicalDevices(instance, &numPhysDevices, null));

    auto physDevices = new VkPhysicalDevice[](numPhysDevices);
    enforceVK(vkEnumeratePhysicalDevices(instance, &numPhysDevices, physDevices.ptr));
    physDevices.map!((d) {
        VkPhysicalDeviceProperties properties;
        vkGetPhysicalDeviceProperties(d, &properties);
        return properties;
    }).each!writeln;

    return 0;
}

