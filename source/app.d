import std.algorithm : map, each;
import std.stdio : writeln, writefln;
import std.exception : enforce;
import std.conv : to;

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

import karasutk.sdl :
    duringSDL,
    EventHandlers,
    runEventLoop,
    Window,
    WindowParameters;

private void enforceVK(VkResult res)
{
	enforce(res == VkResult.VK_SUCCESS, res.to!string);
}

void main()
{
    duringSDL(&vulkanMain);
}

void vulkanMain()
{
    WindowParameters params = {
        vulkan: true
    };
    auto window = Window.create(params);

    auto extensions = window.vulkanInstanceExtensions;

    loadGlobalLevelFunctions();

    VkApplicationInfo appInfo = {
        pApplicationName: "Vulkan sample",
        apiVersion: VK_MAKE_VERSION(1, 0, 2),
    };
    VkInstanceCreateInfo instInfo = {
        pApplicationInfo: &appInfo,
        enabledExtensionCount: cast(uint) extensions.length,
        ppEnabledExtensionNames: extensions.ptr,
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

    EventHandlers eventHandlers;
    window.runEventLoop(eventHandlers);

}

