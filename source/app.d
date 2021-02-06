import std.algorithm : map, each, filter;
import std.string : toStringz;
import std.stdio : writeln, writefln;
import std.exception : enforce;
import std.conv : to;

import erupted :
    loadInstanceLevelFunctions,
    VK_MAKE_VERSION,
    VK_NULL_HANDLE,
    VK_QUEUE_GRAPHICS_BIT,
    VkApplicationInfo,
    vkCreateDevice,
    vkCreateInstance,
    vkDestroyInstance,
    VkDevice,
    VkDeviceCreateInfo,
    VkDeviceQueueCreateInfo,
    vkEnumeratePhysicalDevices,
    vkGetPhysicalDeviceFeatures,
    vkGetPhysicalDeviceProperties,
    vkGetPhysicalDeviceQueueFamilyProperties,
    VkInstance,
    VkInstanceCreateInfo,
    VkPhysicalDevice,
    VkPhysicalDeviceFeatures,
    VkPhysicalDeviceProperties,
    VkQueueFamilyProperties,
    VkResult;

import erupted.vulkan_lib_loader :
    loadGlobalLevelFunctions;

import erupted.dispatch_device :
    DispatchDevice;

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

    loadGlobalLevelFunctions();

    VkApplicationInfo appInfo = {
        pApplicationName: "Vulkan sample",
        apiVersion: VK_MAKE_VERSION(1, 0, 2),
    };

    auto extensions = window.vulkanInstanceExtensions;
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

    // enumerate devices.
    uint numPhysDevices;
    enforceVK(vkEnumeratePhysicalDevices(instance, &numPhysDevices, null));
    auto physDevices = new VkPhysicalDevice[](numPhysDevices);
    enforceVK(vkEnumeratePhysicalDevices(instance, &numPhysDevices, physDevices.ptr));

    enforce(physDevices.length > 0, "Device not found.");

    foreach (device; physDevices)
    {
        VkPhysicalDeviceProperties properties;
        device.vkGetPhysicalDeviceProperties(&properties);
        properties.writeln;

        VkPhysicalDeviceFeatures features;
        device.vkGetPhysicalDeviceFeatures(&features);
        features.writeln;
    }

    auto physDevice = physDevices[0];

    uint queueFamilyCount;
    physDevice.vkGetPhysicalDeviceQueueFamilyProperties(&queueFamilyCount, null);
    auto queueFamilies = new VkQueueFamilyProperties[](queueFamilyCount);
    physDevice.vkGetPhysicalDeviceQueueFamilyProperties(&queueFamilyCount, queueFamilies.ptr);

    uint queueIndex = 0;
    foreach (queue; queueFamilies)
    {
        if (queue.queueFlags & VK_QUEUE_GRAPHICS_BIT)
        {
            break;
        }
        ++queueIndex;
    }

    enforce(queueIndex < queueFamilies.length, "Queue family not found.");

    float queuePriority = 1.0f;
    VkDeviceQueueCreateInfo deviceQueueCreateInfo = {
        queueFamilyIndex: queueIndex,
        queueCount: 1,
        pQueuePriorities: &queuePriority,
    };

    VkPhysicalDeviceFeatures physDeviceFeatures;
    VkDeviceCreateInfo deviceCreateInfo = {
        pQueueCreateInfos: &deviceQueueCreateInfo,
        queueCreateInfoCount: 1,
        pEnabledFeatures: &physDeviceFeatures,
        enabledExtensionCount: 0,
        enabledLayerCount: 0,
    };

    VkDevice device;
    enforceVK(physDevice.vkCreateDevice(&deviceCreateInfo, null, &device));
    auto dispatchDevice = DispatchDevice(device);

    scope(exit) dispatchDevice.DestroyDevice();

    EventHandlers eventHandlers;
    window.runEventLoop(eventHandlers);
}

